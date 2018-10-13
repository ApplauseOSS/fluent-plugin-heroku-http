# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name          = "fluent-plugin-heroku-http"
  gem.version       = "0.0.1"
  gem.authors       = ["Platform Delivery"]
  gem.email         = ["ops@applause.com"]
  gem.description   = %q{fluent plugin to drain heroku http}
  gem.summary       = %q{fluent plugin to drain heroku http}
  gem.homepage      = "https://github.com/ApplauseOSS/fluent-plugin-heroku-http"
  gem.license       = "APLv2"

  gem.files         = `git ls-files`.split($\)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_runtime_dependency "fluentd", ">= 0.10.55"
  gem.add_development_dependency "rake"
  gem.add_development_dependency("test-unit", ["~> 3.0.2"])
end
