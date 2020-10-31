Gem::Specification.new do |s|
	s.name          = "github-mandoc"
	s.version       = "0.0.1"
	s.summary       = "Filters for optimising `mandoc -Thtml` output for display on GitHub.com"
	s.authors       = ["Alhadis"]
	s.homepage      = "https://github.com/Alhadis/github-mandoc"
	s.license       = "ISC"
	
	s.files         = Dir["bin/*"] + Dir["lib/**/*"] + ["LICENSE.md"]
	s.executables   = Dir["bin/*"].map {|exe| File.basename(exe)}
	s.test_files    = Dir["test/*_test.rb"]
	s.require_paths = ["lib"]
	
	s.add_dependency "nokogiri", "~> 1.5.6"
	s.add_development_dependency "bundler", ">= 1.10"
	s.add_development_dependency "minitest", ">= 5.0"
	s.add_development_dependency "simplecov", ">= 0.19"
	s.add_development_dependency "rubocop", "~> 1.1"
end
