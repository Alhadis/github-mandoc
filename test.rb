#!/usr/bin/env ruby
require "open3"
require "nokogiri"

def render(filename, content, options: {})
	source = File.read(`man -w 7 mdoc`.chomp)
	out, _ = Open3.capture2("mandoc -Thtml -Ofragment,man='%N.%S;../%S/%N.%S'", :stdin_data => source)
	filter_html(out)
end

# HTML elements historically known as “inline” elements
PHRASING_ELEMENTS = %q{
	abbr audio b bdo br button canvas cite code command data datalist dfn em embed i
	iframe img input kbd keygen label mark math meter noscript object output picture
	progress q ruby samp script select small span strong sub sup svg textarea time
	var video wbr
}

def filter_html(doc)
	doc = Nokogiri::HTML(doc)
	doc.css("table.head, table.foot").remove
	
	# Replace unwanted or superfluous elements with their contents
	doc.css(".Nd, .permalink, table + br").each {|el| unwrap el}
	
	fix_implicit_paragraph doc
	fix_synopses doc
	replace_unwhitelisted_tags doc
	fix_anchors doc
	
	# Merge adjacent <code> elements
	doc = doc.to_s.gsub %r|</code>\s*<code[^>]*>|i, " "
	
	# Return our spiffy-looking document
	doc
end

# Force lowercase, dash-separated anchor names
def fix_anchors(doc)
	changes = {}
	
	# Normalise IDs
	doc.css("[id]").each do |el|
		old = el["id"]
		changes[old] = el["id"] = fix_anchor(old)
	end
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

# Collect text-nodes that precede the first paragraph break
def fix_implicit_paragraph(doc)
	doc.css("p:first-of-type").each do |el|
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
	if node.is_a? Nokogiri::XML::Node
		PHRASING_ELEMENTS.include? node.name
	else
		node.is_a? String or node.is_a? Nokogiri::XML::CharacterData
	end
end

def unwrap(el)
	nodes = el.children
	el.next= nodes
	el.remove
	nodes
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
	
	# Fix double nesting
	nested = []
	until (nested = doc.css("code code")).empty? do
		nested.each {|el| unwrap(el)}
	end
end

head = File.read("header.html")
body = render(1, 2).to_s
foot = File.read("footer.html")
page = head + body + foot
File.write("index.html", page)
