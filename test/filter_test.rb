# frozen_string_literal: true

require_relative "./helpers"

class FilterTest < Minitest::Test
	Dir["#{FIXTURES}/*"].each do |dir|
		group = File.basename(dir)
		Dir["#{dir}/*.in.html"].each do |input|
			prefix    = File.basename input[0..-9]
			test_name = "test_filtering_of_#{group}_#{prefix}"
			define_method test_name.to_sym do
				expected = html File.read("#{input[0..-9]}.out.html")
				actual   = GitHub::Mandoc.filter File.read(input)
				assert_equal html(actual), expected
			end
		end
	end
end
