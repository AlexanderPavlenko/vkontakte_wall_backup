# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'vkontakte_wall_backup/version'

Gem::Specification.new do |spec|
  spec.name          = "vkontakte_wall_backup"
  spec.version       = VkontakteWallBackup::VERSION
  spec.authors       = ["AlexanderPavlenko"]
  spec.email         = ["alerticus@gmail.com"]
  spec.summary       = %q{Save VK posts as PDF files.}
  spec.description   = %q{.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_dependency "capybara"
  spec.add_dependency "selenium-webdriver"
  spec.add_dependency "geckodriver-helper"
  spec.add_dependency "vkontakte_api"
  spec.add_dependency "hashie", "< 3"
end
