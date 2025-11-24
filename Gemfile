source "https://rubygems.org"

gem "fastlane"

# bundle exec fix for ruby 3.4
gem "abbrev"
gem "csv"

# warnings fix
gem "ostruct"

# ssl connection & certificates fix
gem "openssl"

plugins_path = File.join(File.dirname(__FILE__), 'fastlane', 'Pluginfile')
eval_gemfile(plugins_path) if File.exist?(plugins_path)
