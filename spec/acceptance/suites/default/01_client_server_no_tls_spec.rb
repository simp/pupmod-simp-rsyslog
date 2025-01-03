require 'spec_helper_acceptance'

test_name 'client -> 1 server without TLS'

describe 'rsyslog client -> 1 server without TLS' do
  let(:client) { only_host_with_role(hosts, 'client') }
  let(:server) { hosts_with_role(hosts, 'server').first }
  let(:client_fqdn) { fact_on(client, 'networking.fqdn') }
  let(:server_fqdn) { fact_on(server, 'networking.fqdn') }

  let(:hieradata) do
    <<~EOS
      ---
      iptables::disable : false
      rsyslog::server::enable_firewall : true
    EOS
  end

  let(:client_manifest) do
    <<~EOS
      class { 'rsyslog':
        log_servers        => ['server-1'],
        logrotate          => true,
        enable_tls_logging => false,
        pki                => false,
      }

      rsyslog::rule::remote { 'send_the_logs':
        rule => 'prifilt(\\'*.*\\')',
      }
    EOS
  end
  let(:server_manifest) do
    <<~EOS
      include 'iptables'

      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      class { 'rsyslog':
        tcp_server         => true,
        logrotate          => true,
        enable_tls_logging => false,
        pki                => false,
        trusted_nets       => ['any'],
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
       dyna_file => 'log_everything_by_host',
      }
    EOS
  end

  context 'client -> 1 server without TLS' do
    it 'configures server without errors' do
      set_hieradata_on(server, hieradata)
      apply_manifest_on(server, server_manifest, catch_failures: true)
    end

    it 'configures server idempotently' do
      apply_manifest_on(server, server_manifest, catch_changes: true)
    end

    it 'configures client without errors' do
      apply_manifest_on(client, client_manifest, catch_failures: true)
    end

    it 'configures client idempotently' do
      apply_manifest_on(client, client_manifest, catch_changes: true)
    end

    it 'successfullies send log messages' do
      on client, 'logger -t FOO TEST-WITHOUT-TLS'
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on server, "test -f #{remote_log}"
      on server, "grep TEST-WITHOUT-TLS #{remote_log}"
    end
  end
end
