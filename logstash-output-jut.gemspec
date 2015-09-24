Gem::Specification.new do |s|
  s.name = 'logstash-output-jut'
  s.version = "0.2"
  s.licenses = ["Apache License (2.0)"]
  s.summary = "sends records to a Jut data engine"
  s.description = "logstash output plugin that sends records to a Jut data engine"
  s.authors = ["Jut, Inc."]
  s.email = "josa@jut.io"
  s.homepage = "https://github.com/jut-io/logstash-output-jut"
  s.require_paths = ["lib"]

  # Files
  s.files = `git ls-files`.split($\)
   # Tests
  s.test_files = s.files.grep(%r{^(test|spec|features)/})

  # Special flag to let us know this is actually a logstash plugin
  # This metadata attribute blew up for me on Ubuntu 14.04 with the latest rubgems installed
  s.metadata = { "logstash_plugin" => "true", "logstash_group" => "output" }

  # Gem dependencies
  s.add_runtime_dependency "logstash-core", ">= 1.4.0", "< 2.0.0"
  s.add_runtime_dependency "logstash-codec-plain"
  s.add_runtime_dependency "work_queue"

  s.add_development_dependency "logstash-devutils"
end
