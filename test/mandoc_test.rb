# frozen_string_literal: true

require "simplecov"
require "minitest/autorun"
require "github/mandoc"

class MandocTest < Minitest::Test
	def setup
		@fixtures = File.expand_path("fixtures", __dir__)
	end

	def test_filtering
		Dir["#{@fixtures}/*.input.html"].each do |file|
			exp = file.sub(/(?<=\.)input(?=\.html$)/i, "output")
			exp = File.read(exp)
			act = GitHub::Mandoc.filter(File.read(file)).to_s
			assert_equal exp, act, "Mismatch: #{file}"
		end
	end

	def test_filtered_mandoc_output
		Dir["#{@fixtures}/*.[1-9]"].each do |file|
			exp = File.read("#{file}.html")
			act = GitHub::Mandoc.render(File.read(file)).to_s
			assert_equal exp, act, "Mismatch: #{file}"
		end
	end
end
