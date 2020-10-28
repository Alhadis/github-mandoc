#!/usr/bin/env ruby
require "open3"
require "nokogiri"
require "pp"

def render(filename, content, options: {})
	source = File.read(`man -w mdoc`.chomp)
	out, _ = Open3.capture2("mandoc -Thtml -Ofragment,man='%N.%S;../man%S/%N.%S'", :stdin_data => source)
	filter_html(out, filename)
end

INLINE_ELEMENTS = %w[
	a abbr acronym audio b bdi bdo big br button canvas cite code command data datalist
	del dfn em embed i iframe img input ins kbd keygen label map mark math meter noscript
	object output picture progress q ruby s samp script select slot small span strong sub
	sup svg template textarea time tt u var video wbr
]

BLOCK_ELEMENTS = %w[
	address article aside blockquote dd details dialog div dl dt fieldset figcaption figure
	footer form h1 h2 h3 h4 h5 h6 header hgroup hr li main nav ol p pre section table ul
]

def filter_html(doc, path = "")
	doc = Nokogiri::HTML(doc)
	doc.css("table.head, table.foot").remove
	
	# Replace unwanted or superfluous elements with their contents
	doc.css(".Nd, .permalink, table + br").each {|el| unwrap el}
	
	fix_implicit_paragraphs doc
	fix_synopses doc
	fix_anchors doc
	replace_unwhitelisted_tags doc
	fix_broken_references doc, path
	
	# Merge adjacent <code> elements
	doc.inner_html = doc.root.to_s
		.gsub(%r|</code\s*>\s+<code[^>]*>|i, " ")
		.gsub(%r|</code\s*><code[^>]*>|i, "")
	
	# Strip empty paragraph nodes
	doc.css("p").each {|p| p.remove unless p.content =~ /\S/}
	
	# Return our spiffy-looking document
	doc
end

# Force lowercase, dash-separated anchor names
def fix_anchors(doc)
	map = {}
	
	# Normalise IDs
	doc.css("[id]").each do |el|
		old = el["id"]
		id = fix_anchor(old)
		while map.has_value? id do
			id.sub!(/\d*$/) {|suffix| (suffix || "1").to_i + 1}
		end
		map[old] = el["id"] = id
	end
	
	# Update hrefs
	doc.css("[href]").each do |el|
		href = el["href"]
		if href =~ /#([^#]+)$/ and map.has_key? $1
			el["href"] = href.gsub /[^#]+$/, map[$1]
		end
	end
	
	map
end

# Replace “SHOUTING_SNAKE_CASE” with “calm-kebab-case”
def fix_anchor(id)
	id.downcase.gsub(/[_\W]+|-{2,}/, "-").gsub(/^-|-$/, "")
end

# Merge synopsis tables and use <th> where appropriate
def fix_synopses(doc)
	table = doc.at_css("table.Nm")
	doc.css("table.Nm ~ table.Nm > tr").each do |row|
		row.parent.remove
		table.add_child row
	end
	doc.css("table.Nm > tr > td:first-child").each {|el| el.name = "th"}
	doc.css("table.Nm > tr > *").each {|el| el["valign"] = "top"}
end

# Collect text-nodes that precede the first block element
def fix_implicit_paragraphs(doc)
	doc.css("blockquote, div, dl, ol, p, pre, table, ul").each do |el|
		nodes = Nokogiri::XML::NodeSet.new doc
		while inline?(prev = el.previous_sibling) do
			nodes << el.previous_sibling.unlink
		end
		unless nodes.empty?
			p = doc.create_element "p"
			p.children= nodes.reverse
			el.previous= p
		end
	end
end

def inline?(node)
	if node.is_a? Nokogiri::XML::Element
		INLINE_ELEMENTS.include? node.name
	else
		node.is_a? String or node.is_a? Nokogiri::XML::Text
	end
end

def unwrap(el)
	nodes = el.children
	el.next= nodes
	el.remove
	nodes
end

# Remove cross-references that point to missing files
def fix_broken_references(doc, filename = __FILE__)
	doc.css(".Xr[href]").each do |a|
		path = File.expand_path a["href"], filename
		unless File.exist?(path)
			unwrap a
		end
	end
end

# Replace elements that aren't included in GitHub's HTML whitelist
def replace_unwhitelisted_tags(doc)
	# Monospace + bold
	doc.css(".Cd, .Cm, .Fd, .Fl, .Fn, .Ic, .In, code.Nm").each do |el|
		bold = doc.create_element "b"
		code = doc.create_element "code", el.inner_text
		bold.add_child code
		el.children= bold
	end
	
	# Plain monospace
	doc.css(".Ad").wrap "<samp></samp>"
	doc.css(".Pa, .Xr").wrap "<code></code>"
	
	# Fix double nesting
	nested = []
	until (nested = doc.css("code code")).empty? do
		nested.each {|el| unwrap(el)}
	end
end

head = File.read("header.html")
body = render("/usr/local/share/man/man7", 2).to_s
foot = File.read("footer.html")
page = head + body + foot
File.write("index.html", page)
