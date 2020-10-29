require "minitest/autorun"

class MandocTest < Minitest::Test
	def setup
		@fixtures = File.expand_path("../fixtures", __FILE__)
	end

	def test_filtering
		Dir["#{@fixtures}/*.input.html"].each do |file|
			exp = file.sub /(?<=\.)input(?=\.html$)/i, "output"
			exp = File.read(exp)
			act = GitHub::Mandoc.filter(File.read file)
			assert_equal exp, act, "Mismatch: #{file}"
		end
	end

	def test_filtered_mandoc_output
		Dir["#{@fixtures}/*.[1-9]"].each do |file|
			exp = File.read("#{file}.html")
			act = GitHub::Mandoc.render(File.read file)
			assert_equal exp, act, "Mismatch: #{file}"
		end
	end
end
