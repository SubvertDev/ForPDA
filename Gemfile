source "https://rubygems.org"

gem "fastlane", "2.229.1"

# warnings fix
gem "ostruct"

# telegram notify fix
gem "openssl"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
