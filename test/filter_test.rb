# frozen_string_literal: true

require "simplecov"
require "minitest/autorun"
require "github/mandoc"

class FilterTest < Minitest::Test
	fixtures = File.expand_path("fixtures", __dir__)

	Dir["#{fixtures}/*"].each do |dir|
		group = File.basename(dir)
		Dir["#{dir}/*.in.html"].each do |input|
			prefix    = File.basename input[0..-9]
			test_name = "test_filtering_of_#{group}_#{prefix}"
			define_method test_name.to_sym do
				expected = File.read("#{input[0..-9]}.out.html")
				actual   = GitHub::Mandoc.filter File.read(input)
				assert_equal expected, actual
			end
		end
	end
end
