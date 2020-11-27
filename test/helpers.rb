# frozen_string_literal: true

require "simplecov"
require "minitest/autorun"
require "nokogiri/diff"
require "active_support/xml_mini/nokogiri"
require "github/mandoc"

FIXTURES = File.expand_path("fixtures", __dir__)

def html(input)
	if input.is_a? GitHub::Mandoc::Rendering
		doc = input.doc
	else
		frag = Nokogiri::HTML::DocumentFragment.parse(input)
		doc = frag.first_element_child
	end
	doc.to_html.sub(/\n?\z/, "\n")
end
