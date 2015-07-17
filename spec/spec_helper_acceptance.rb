require 'beaker-rspec'

unless ENV['BEAKER_provision'] == 'no'
  hosts.each do |host|
    # Install Puppet
    if host.is_pe?
      install_pe
    else
      install_puppet
    end
  end
end

# returns an Array of puppet modules declared in .fixtures.yml
def pupmods_in_fixtures_yaml
  require 'yaml'
  fixtures_yml = File.expand_path( '../.fixtures.yml', File.dirname(__FILE__))
  data         = YAML.load_file( fixtures_yml )
  repos        = data.fetch('fixtures').fetch('repositories').keys
  symlinks     = data.fetch('fixtures').fetch('symlinks', {}).keys
  (repos + symlinks)
end


RSpec.configure do |c|
  # Project root
  proj_root = File.expand_path(File.join(File.dirname(__FILE__), '..'))

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # net-tools required for netstat utility being used by be_listening
    if fact('osfamily') == 'RedHat' && fact('operatingsystemmajrelease') == '7'
      pp = <<-EOS
        package { 'net-tools': ensure => installed }
      EOS

      apply_manifest_on(agents, pp, :catch_failures => false)
    end

    # Install module and dependencies
    puppet_module_install(:source => proj_root, :module_name => 'dummy')
    hosts.each do |host|
      # allow spec_prep to provide modules (to support isolated networks)
      if ENV['BEAKER_use_fixtures_dir_for_modules'] == 'yes'
        pupmods_in_fixtures_yaml.each do |pupmod|
          mod_root = File.expand_path( "fixtures/modules/#{pupmod}", File.dirname(__FILE__))
          puppet_module_install(:source => mod_root, :module_name => pupmod)
        end
      else
        # TODO: update when the relevant SIMP modules are on the forge
        on host, puppet('module', 'install', 'puppetlabs-stdlib'), { :acceptable_exit_codes => [0,1] }
      end
    end
  end
end
