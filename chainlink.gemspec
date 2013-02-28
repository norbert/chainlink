Gem::Specification.new do |s|
  s.name        = "chainlink"
  s.version     = "0.1.0"
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Norbert Crombach"]
  s.email       = ["norbert.crombach@primetheory.org"]
  s.homepage    = "http://github.com/norbert/chainlink"
  s.summary     = %q{Simple ActiveRecord plugin for handling merges.}

  s.rubyforge_project = "chainlink"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = s.files.grep(/^test\//)
  s.require_paths = ["lib"]

  s.add_dependency 'activerecord', '~> 3.2.0'
  s.add_development_dependency 'rake'
  s.add_development_dependency 'mocha'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'mysql2'
  s.add_development_dependency 'pg'
end
