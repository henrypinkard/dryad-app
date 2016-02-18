$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'stash_discovery/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'stash_discovery'
  s.version     = StashDiscovery::VERSION
  s.authors     = ['David Moles']
  s.email       = ['david.moles@ucop.edu']
  s.homepage    = 'TODO'
  s.summary     = 'TODO: Summary of StashDiscovery.'
  s.description = 'TODO: Description of StashDiscovery.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '~> 4.2'
  s.add_dependency 'geoblacklight', '~> 0.12.1'

  # extra deps from generated GeoBlacklight app
  s.add_dependency 'devise-guests', '~> 0.3'

  s.add_development_dependency 'sqlite3'
end
