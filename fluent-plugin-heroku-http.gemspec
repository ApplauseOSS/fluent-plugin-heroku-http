# frozen_string_literal: true

Gem::Specification.new do |gem|
  gem.name          = 'fluent-plugin-heroku-http'
  gem.version       = '0.0.2'
  gem.authors       = ['Platform Delivery']
  gem.email         = ['ops@applause.com']
  gem.description   = 'fluent plugin to drain heroku http'
  gem.summary       = 'fluent plugin to drain heroku http'
  gem.homepage      = 'https://github.com/ApplauseOSS/fluent-plugin-heroku-http'
  gem.license       = 'APLv2'
  gem.required_ruby_version = '3.1.0'

  gem.files         = `git ls-files`.split($OUTPUT_RECORD_SEPARATOR)
  gem.executables   = gem.files.grep(%r{^bin/}).map { |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'fluentd', '>= 1.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency('test-unit', ['~> 3.5.3'])
end
