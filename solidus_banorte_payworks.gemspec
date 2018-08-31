# encoding: UTF-8
$:.push File.expand_path('../lib', __FILE__)
require 'solidus_banorte_payworks/version'

Gem::Specification.new do |s|
  s.name        = 'solidus_banorte_payworks'
  s.version     = SolidusBanortePayworks::VERSION
  s.summary     = 'Solidus Banorte Payworks Gateway'
  s.description = s.summary
  s.license     = 'BSD-3-Clause'

  s.author    = 'Jonathan Tapia'
  s.email     = 'jonathan.tapia@magmalabs.io'
  s.homepage  = 'http://github.com/jtapia/solidus_banorte_payworks'
  s.license   = 'BSD-3-Clause'

  s.files = Dir["{app,config,db,lib}/**/*", 'LICENSE', 'Rakefile', 'README.md']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'solidus', ['>= 1.0', '< 3']
  s.add_dependency 'solidus_support'
  s.add_dependency 'banorte_payworks'

  s.add_development_dependency 'capybara'
  s.add_development_dependency 'poltergeist'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'sass-rails'
  s.add_development_dependency 'database_cleaner'
  s.add_development_dependency 'factory_bot'
  s.add_development_dependency 'rspec-rails'
  s.add_development_dependency 'rubocop'
  s.add_development_dependency 'rubocop-rspec'
  s.add_development_dependency 'simplecov'
  s.add_development_dependency 'sqlite3'
end
