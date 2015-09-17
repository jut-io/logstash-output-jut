# Batch HTTP Plugin

This is a plugin for [Logstash](https://github.com/elasticsearch/logstash).

## Documentation

This plugin sends events to a [Jut](https://jut.io) data engine.
Events are formatted to be suitable for
[direct import via http](http://docs.jut.io/user-guide/#data_ingest_http)
and are grouped into batches to reduce the total number of http
transactions required to import many records.

## Developing

### 1. Plugin Developement and Testing

#### Code
- To get started, you'll need JRuby with the Bundler gem installed.

- Install dependencies
```sh
bundle install
```

#### Test

- Update your dependencies

```sh
bundle install
```

- Run tests

```sh
bundle exec rspec
```

### 2. Running your unpublished Plugin in Logstash

#### 2.1 Run in a local Logstash clone 

##### 2.1.1 Version 1.5 and above

- Edit Logstash `Gemfile` and add the local plugin path, for example:
```ruby
gem "logstash-output-jut", :path => "/your/local/logstash-output-jut"
```
- Install plugin
```sh
bin/plugin install --no-verify
```
- Run Logstash with your plugin
```sh
bin/logstash -e 'input { stdin {} } output { jut { url => URL }}'
```
At this point any modifications to the plugin code will be applied to this local Logstash setup. After modifying the plugin, simply rerun Logstash.

##### 2.1.1 Version 1.4 and below

- Copy the files jut.rb and HTTPBatcher.rb into /path/to/logstash-1.4.2/lib/logstash/outputs/

- Run Logstash with your plugin
```sh
bin/logstash -e 'input { stdin {} } output { jut { url => URL }}'
```

#### 2.2 Run in an installed Logstash

You can use the same **2.1** method to run your plugin in an installed Logstash by editing its `Gemfile` and pointing the `:path` to your local plugin development directory or you can build the gem and install it using:

- Build your plugin gem
```sh
gem build logstash-output-jut.gemspec
```
- Install the plugin from the Logstash home
```sh
bin/plugin install /your/local/plugin/logstash-output-jut.gem
```
- Start Logstash and proceed to test the plugin