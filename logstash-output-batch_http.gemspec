Gem::Specification.new do |s|
  s.name = 'logstash-output-batch_http'
  s.version = "0.1.1"
  s.licenses = ["Apache License (2.0)"]
  s.summary = "Batches HTTP POST requests"
  s.description = "logstash output plugin that posts a json array of multiple records"
  s.authors = ["Stephan Liu - Jut, Inc."]
  s.email = "stephan.x.liu@gmail.com"
  s.homepage = "https://github.com/jut-io/logstash-output-batch_http"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 1.4.0", "< 2.0.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_development_dependency "logstash-devutils"
  s.add_runtime_dependency 'ftw', ['~> 0.0.40']
  s.add_runtime_dependency 'typhoeus', ">= 0.7.1"
end
