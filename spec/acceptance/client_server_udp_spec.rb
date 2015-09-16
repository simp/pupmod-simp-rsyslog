require 'spec_helper_acceptance'

test_name 'client -> server using UDP'

describe 'rsyslog class' do
  before(:all) do
    # Ensure that our test doesn't match messages from other tests
    sleep(1)
    @msg_uuid = Time.now.to_f.to_s.gsub('.','_') + '_UDP'
  end

  let(:client){ only_host_with_role( hosts, 'client' ) }
  let(:client_fqdn){ fact_on( client, 'fqdn' ) }
  let(:server){ hosts_with_role( hosts, 'server' ).first }

  let(:client_manifest_hieradata) {
    {
      'rsyslog::log_server_list'    => ['server-1'],
      'rsyslog::enable_logrotate'   => true,
      'rsyslog::enable_tls_logging' => false,
      'rsyslog::enable_pki'         => false
    }
  }
  let(:client_manifest) {
    <<-EOS
      include 'rsyslog'

      rsyslog::rule::remote { 'send_the_logs':
        dest_type => 'udp',
        rule => '*.*'
      }
    EOS
  }

  let(:server_manifest_hieradata) {
    {
      'rsyslog::udp_server'                 => true,
      'rsyslog::enable_logrotate'           => true,
      'rsyslog::enable_pki'                 => false,
      'rsyslog::client_nets'                => 'any',
      'rsyslog::server::enable_firewall'    => true,
      'rsyslog::server::enable_selinux'     => true,
      # If you enable this, you need to make sure to add a tcpwrappers rule
      # for sshd
      'rsyslog::server::enable_tcpwrappers' => false
    }
  }
  let(:server_manifest) {
    <<-EOS
      # Turns off firewalld in EL7.  Presumably this would already be done.
      include '::iptables'
      iptables::add_tcp_stateful_listen { 'ssh':
        dports => '22',
        client_nets => 'any'
      }

      include 'rsyslog'
      include 'rsyslog::server'

      # define a dynamic file with an rsyslog template
      # NOTE: puppet doesn't need to manage missing directories in this path;
      #       rsyslog will create them as needed.
      rsyslog::template::string { 'log_everything_by_host':
        string => '/var/log/hosts/%HOSTNAME%/everything.log'
      }

      # log all messages to the dynamic file we just defined ^^
      rsyslog::rule::local { 'all_the_logs':
       rule => '*.*',
       dyna_file => 'log_everything_by_host'
      }
    EOS
  }

  context 'client -> server over UDP' do
    it 'should configure the server without errors' do
      set_hieradata_on(server, server_manifest_hieradata)
      apply_manifest_on(server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    it 'should configure the server idempotently' do
      apply_manifest_on(server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_changes => true)
    end

    it 'should configure the client without errors' do
      set_hieradata_on(client, client_manifest_hieradata)
      apply_manifest_on(client, client_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    it 'should configure client idempotently' do
      apply_manifest_on(client, client_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    it 'should successfully send log messages to the server over UDP' do
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on client, "logger -t FOO TEST-1-#{@msg_uuid}-MSG"

      on server, "test -f #{remote_log}"
      on server, "grep TEST-1-#{@msg_uuid}-MSG #{remote_log}"
    end
  end
end
