require "nokogiri"
require "open3"

module GitHub
	module Mandoc
		VERSION = "0.0.1"
		
		# Locate a man page by topic/section, then render it
		def self.render_topic(name, section = "")
			path = `man -w #{section} #{name}`.chomp
			return unless $?.success?
			self.render_file(path)
		end
		
		# Load and render a man page from the designated location
		def self.render_file(path)
			self.render(File.read(path), path)
		end
		
		# Shell out to mandoc(1) to format man(7) or mdoc(7) markup as HTML
		def self.render(source, filename = "")
			out, _ = Open3.capture2("mandoc -Thtml -Ofragment,man='%N.%S;../man%S/%N.%S'", :stdin_data => source)
			self.filter(out, filename)
		end

		# Filter preformatted HTML
		def self.filter(source, filename = "")
			Rendering.new(source, filename)
		end


		# Container for a rendered and filtered man page
		class Rendering
			attr_reader :doc, :path

			def initialize(source = "", path = "")
				filter(source, path) if source
			end
			
			# Optimise the output of `mandoc -Thtml`
			def filter(source, path = "")
				@doc = Nokogiri::HTML(source)
				@path = path
				@doc.css("table.head, table.foot").remove
				
				# Replace unwanted or superfluous elements with their contents
				@doc.css(".Nd, .permalink, table + br").each {|el| unwrap el}
				
				fix_implicit_paragraphs
				fix_synopses
				fix_anchors
				replace_unwhitelisted_tags
				fix_broken_references
				
				# Merge adjacent <code> elements
				@doc.inner_html = @doc.root.to_s
					.gsub(%r|</code\s*>\s+<code[^>]*>|i, " ")
					.gsub(%r|</code\s*><code[^>]*>|i, "")
					.gsub(%r|(?>\R[ \t]*)+</pre>|, "\n</pre>")
				
				# Strip empty paragraph nodes
				@doc.css("p").each {|p| p.remove unless p.content =~ /\S/}
				
				# Make indented regions more conspicuous
				upgrade_displays
				
				# Strip redundant line-breaks for more consistent testing
				@doc.css("h1, h2, h3, h4, h5, h6, p, a").each {|el| normalise_whitespace el}
				@doc.inner_html = @doc.root.to_s.gsub(%r{<p(?=\s|>)[^>]*>\K +| +(?=</p>)}, "")
				
				# Finally, strip CSS classes so output matches that of GitHub's HTML sanitiser
				@doc.css("[class]").remove_attr("class")
				
				# Return instance for easier chaining
				return self
			end

			# Return the HTML source for the rendered and filtered document
			def to_s()   @doc.to_s; end
			def to_str() to_s;      end

			# Return true if the argument belongs in a <p> element
			def inline?(node)
				if node.is_a? Nokogiri::XML::Element
					INLINE_ELEMENTS.include? node.name
				else
					node.is_a? String or node.is_a? Nokogiri::XML::Text
				end
			end

			# Remove an HTML tag, but not its contents
			def unwrap(el)
				nodes = el.children
				el.next= nodes
				el.remove
				nodes
			end

		private
			# Replace “SHOUTING_SNAKE_CASE” with “calm-kebab-case”
			def fix_anchor(id)
				id.downcase.gsub(/[_\W]+|-{2,}/, "-").gsub(/^-|-$/, "")
			end
		
			# Force lowercase, dash-separated anchor names
			def fix_anchors
				map = {}
				
				# Normalise IDs
				@doc.css("[id]").each do |el|
					old = el["id"]
					id = fix_anchor(old)
					while map.has_value? id do
						id.sub!(/\d*$/) {|suffix| (suffix || "1").to_i + 1}
					end
					map[old] = el["id"] = id
				end
				
				# Update hrefs
				@doc.css("[href]").each do |el|
					href = el["href"]
					if href =~ /#([^#]+)$/ and map.has_key? $1
						el["href"] = href.gsub /[^#]+$/, map[$1]
					end
				end
			end

			# Remove cross-references that point to missing files
			def fix_broken_references
				@doc.css(".Xr[href]").each do |el|
					path = File.expand_path el["href"], @path
					unwrap el unless File.exist?(path)
				end
			end

			# Collect text-nodes that precede the first block element
			def fix_implicit_paragraphs
				@doc.css("blockquote, div, dl, ol, p, pre, table, ul").each do |el|
					nodes = Nokogiri::XML::NodeSet.new @doc
					while inline?(prev = el.previous_sibling) do
						nodes << el.previous_sibling.unlink
					end
					unless nodes.empty?
						p = @doc.create_element "p"
						p.children= nodes.reverse
						el.previous= p
					end
				end
			end

			# Merge synopsis tables and use <th> where appropriate
			def fix_synopses
				table = @doc.at_css("table.Nm")
				@doc.css("table.Nm ~ table.Nm > tr").each do |row|
					row.parent.remove
					table.add_child row
				end
				@doc.css("table.Nm > tr > td:first-child").each {|el| el.name = "th"}
				@doc.css("table.Nm > tr > *").each {|el| el["valign"] = "top"}
			end

			# Normalise whitespace in non-monospaced elements
			def normalise_whitespace(el)
				return unless el.ancestors("pre").empty?
				el.children.each do |node|
					if node.is_a? Nokogiri::XML::Text
						node.content= node.content.gsub /\s+/, " "
					end
				end
			end

			# Replace elements that aren't included in GitHub's HTML whitelist
			def replace_unwhitelisted_tags
				# Monospace + bold
				@doc.css(".Cd, .Cm, .Fd, .Fl, .Fn, .Ic, .In, code.Nm").each do |el|
					bold = @doc.create_element "b"
					code = @doc.create_element "code", el.inner_text
					bold.add_child code
					el.children= bold
				end

				# Plain monospace
				@doc.css(".Ad").wrap "<samp></samp>"
				@doc.css(".Pa, .Xr").wrap "<code></code>"

				# Fix double nesting
				nested = []
				until (nested = @doc.css("code code")).empty? do
					nested.each {|el| unwrap(el)}
				end
			end

			# Replace displays with their closest HTML equivalents
			def upgrade_displays
				@doc.css(".Bd > pre:only-child").each do |el|
					unwrap el.parent
				end

				# Concatenate element lists composed solely of <code> tags
				@doc.css(".Bd").each do |bd|
					if bd.children.all? {|el| "code" == el.name}
						pre = @doc.create_element "pre", "\n", :class => "inline"
						bd.children.each {|el| normalise_whitespace el}
						pre.add_child bd.children
						bd.previous= pre
						bd.remove
					end
				end

				# Merge adjacent displays generated by the previous step
				until (inline = @doc.css("pre.inline + pre.inline")).empty? do
					inline.each do |el|
						el.previous_element << el.children
						el.remove
					end
				end

				# HACK: Enclose remaining (indented) displays in <ul> elements
				@doc.css("div.Bd-indent").wrap "<ul></ul>"
			end
		end
	end

	# HTML elements that fit inside a <p> element. Source: https://mdn,io/Inline_elements
	INLINE_ELEMENTS = %w[
		a abbr acronym audio b bdi bdo big br button canvas cite code command data datalist
		del dfn em embed i iframe img input ins kbd keygen label map mark math meter noscript
		object output picture progress q ruby s samp script select slot small span strong sub
		sup svg template textarea time tt u var video wbr
	]

	# HTML elements that *don't* fit inside a <p> element. Source: https://mdn.io/Block_elements
	BLOCK_ELEMENTS = %w[
		address article aside blockquote dd details dialog div dl dt fieldset figcaption figure
		footer form h1 h2 h3 h4 h5 h6 header hgroup hr li main nav ol p pre section table ul
	]
end
