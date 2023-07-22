# frozen_string_literal: true

require_relative "lib/nequi/version"

Gem::Specification.new do |spec|
  spec.name = "nequi"
  spec.version = "0.1.6"
  spec.authors = ["geocodinglife"]
  spec.email = ["geocodinglife@gmail.com"]

  spec.summary = "A Ruby gem to connect with Nequi payments systems."
  spec.description = "Nequi gem provides a convenient way to integrate with Nequi payments systems for processing payments and other related operations."
  spec.homepage = "https://github.com/geocodinglife/nequi"
  spec.license = "MIT"
  spec.required_ruby_version = ">= 2.6.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = spec.homepage
  spec.metadata["changelog_uri"] = "#{spec.homepage}/CHANGELOG.md"

  # Specify which files should be added to the gem when it is released.
  spec.files = Dir["lib/**/*"]

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  spec.add_dependency 'httparty', '~> 0.21.0'
  spec.add_dependency 'dotenv-rails', '~> 2.8', '>= 2.8.1'
  spec.add_dependency 'vcr', '~> 6.2'
  spec.add_dependency 'webmock', '~> 3.18', '>= 3.18.1'

  # For more information and examples about making a new gem, check out our
  # guide at: https://bundler.io/guides/creating_gem.html
end
