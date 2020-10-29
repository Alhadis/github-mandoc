require File.expand_path("../lib/github/mandoc", __FILE__)

Gem::Specification.new do |s|
	s.name          = "github-mandoc"
	s.version       = GitHub::Mandoc::VERSION
	s.summary       = "Filters for optimising `mandoc -Thtml` output for display on GitHub.com"
	s.authors       = ["Alhadis"]
	s.homepage      = "https://github.com/Alhadis/github-mandoc"
	s.license       = "ISC"
	
	s.files         = Dir["bin/*"] + Dir["lib/**/*"] + ["LICENSE.md"]
	s.executables   = Dir["bin/*"].map {|exe| File.basename(exe)}
	s.test_files    = Dir["tests/**/*"]
	s.require_paths = ["lib"]
	
	s.add_dependency "nokogiri", "~> 1.5.6"
end