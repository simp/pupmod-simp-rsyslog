require 'spec_helper_acceptance'

test_name 'client -> 1 server using TLS'

describe 'rsyslog client -> 1 server using TLS' do

  before(:context) do
    hosts.each do |host|
      interfaces = fact_on(host, 'interfaces').strip.split(',')
      interfaces.delete_if do |x|
        x =~ /^lo/
      end

      interfaces.each do |iface|
        if fact_on(host, "ipaddress_#{iface}").strip.empty?
          on(host, "ifup #{iface}", :accept_all_exit_codes => true)
        end
      end
    end
  end

  let(:client){ only_host_with_role( hosts, 'client' ) }
  let(:server){ hosts_with_role( hosts, 'server' ).first }
  let(:client_fqdn){ fact_on( client, 'fqdn' ) }
  let(:server_fqdn){ fact_on( server, 'fqdn' ) }
  let(:client_manifest) {
    <<-EOS
      class { 'rsyslog':
        log_servers        => ["#{server_fqdn}"],
        logrotate          => true,
        enable_tls_logging => true,
        pki                => false,
        app_pki_dir        => '/etc/pki/simp-testing/pki',
      }

      rsyslog::rule::remote { 'send_the_logs':
        rule => 'prifilt(\\'*.*\\')'
      }
    EOS
  }

  let(:hieradata) {
    <<-EOS
---
iptables::disable : false
rsyslog::server::enable_firewall : true
    EOS
  }
  let(:server_manifest) {
    <<-EOS
      # Turns off firewalld in EL7.  Presumably this would already be done.
      include 'iptables'
      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      class { 'rsyslog':
        log_servers        => ["#{server_fqdn}"],
        tls_tcp_server     => true,
        logrotate          => true,
        enable_tls_logging => true,
        pki                => false,
        app_pki_dir        => '/etc/pki/simp-testing/pki',
        trusted_nets       => ['any']
      }

      class { 'rsyslog::server':
        enable_firewall    => true,
        enable_selinux     => false,
        enable_tcpwrappers => false,
      }

      # define a dynamic file with an rsyslog template
      # NOTE: puppet doesn't need to manage missing directories in this path;
      #       rsyslog will create them as needed.
      rsyslog::template::string { 'log_everything_by_host':
        string => '/var/log/hosts/%HOSTNAME%/everything.log',
      }

      # log all messages to the dynamic file we just defined ^^
      rsyslog::rule::local { 'all_the_logs':
        rule      => 'prifilt(\\'*.*\\')',
        dyna_file => 'log_everything_by_host'
      }
    EOS
  }

  context 'client -> 1 server with TLS' do
    it 'should configure server without errors' do
      set_hieradata_on(server, hieradata)
      apply_manifest_on(server, server_manifest, :catch_failures => true)
    end

    it 'should configure server idempotently' do
      apply_manifest_on(server, server_manifest, :catch_changes => true)
    end

    it 'should configure client without errors' do
      apply_manifest_on(client, client_manifest, :catch_failures => true)
    end

    it 'should configure client idempotently' do
      apply_manifest_on(client, client_manifest, :catch_changes => true)
    end

    it 'should successfully send log messages' do
      on client, 'logger -t FOO TEST-USING-TLS'
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on server, "test -f #{remote_log}"
      on server, "grep TEST-USING-TLS #{remote_log}"
    end
  end
end
