source "https://rubygems.org"

gem "fastlane"

# telegram notify fix for CI
gem "openssl"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
