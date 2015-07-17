# Variables:
#
# SIMP_GEM_SERVERS | a space/comma delimited list of rubygem servers
# PUPPET_VERSION   | specifies the version of the puppet gem to load
puppetversion = ENV.key?('PUPPET_VERSION') ? "#{ENV['PUPPET_VERSION']}" : ['~>3']
gem_sources   = ENV.key?('SIMP_GEM_SERVERS') ? ENV['SIMP_GEM_SERVERS'].split(/[, ]+/) : ['https://rubygems.org']

gem_sources.each { |gem_source| source gem_source }

group :test do
  gem "rake"
  gem 'puppet', puppetversion
  gem "rspec", '< 3.2.0'
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem "puppetlabs_spec_helper"
  gem "metadata-json-lint"
  gem "simp-rspec-puppet-facts"

  # simp-rake-helpers does not suport puppet 2.7.X
  # FIXME: simp-rake-helpers should support Puppet 4.X
  if (!(['2','4'].include?( "#{ENV['PUPPET_VERSION']}".scan(/\d+/).first)) &&
      ("#{ENV['PUPPET_VERSION']}" !~ /~> ?(2|4)/ ? true : false) ) &&
      # simp-rake-helpers and ruby 1.8.7 bomb Travis tests
      # TODO: fix upstream deps (parallel in simp-rake-helpers)
      !( ENV['TRAVIS'] && RUBY_VERSION.sub(/\.\d+$/,'') == '1.8' )
    gem 'simp-rake-helpers'
  end
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
  gem "guard-rake"
  gem 'pry'
  gem 'pry-doc'
end

group :system_tests do
  gem "beaker"
  gem "beaker-rspec"
end
