# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'roda/component/version'

Gem::Specification.new do |spec|
  spec.name          = "roda-component"
  spec.version       = Roda::Component::VERSION
  spec.authors       = ["cj"]
  spec.email         = ["cjlazell@gmail.com"]
  spec.summary       = %q{}
  spec.description   = %q{}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "opal", "~> 0.7.0.beta3"
  spec.add_runtime_dependency "opal-jquery", "~> 0.3.0.beta2"
  spec.add_runtime_dependency "redis-rack"
  spec.add_runtime_dependency "rest-client"
  spec.add_runtime_dependency "faye", '~> 1.1.0'
  spec.add_runtime_dependency "ability_list", '~> 0.0.4'
  spec.add_runtime_dependency "faye-redis"
  spec.add_runtime_dependency "redic", "~> 1.1.1"
  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "pry-test", "~> 0.5.5"
  spec.add_development_dependency "roda", "~> 1.1.0"
  spec.add_development_dependency "thin"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "pry-rescue"
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "pry-stack_explorer"
  spec.add_development_dependency "pry-doc"
  spec.add_development_dependency "awesome_print"
  spec.add_development_dependency "hirb"
  spec.add_development_dependency "rubocop"
  spec.add_development_dependency "rack-unreloader"
  spec.add_development_dependency "poltergeist", "~> 1.5.1"
end
