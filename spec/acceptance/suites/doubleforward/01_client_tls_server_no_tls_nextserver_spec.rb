require 'spec_helper_acceptance'

test_name 'client -> 1 server using TLS -> 1 server using plain TCP'

describe 'rsyslog client -> 1 server using TLS -> 1 server using plain TCP' do
  let(:client) { only_host_with_role(hosts, 'client') }
  let(:server) { only_host_with_role(hosts, 'server') }
  let(:nextserver) { only_host_with_role(hosts, 'nextserver') }
  let(:client_fqdn) { fact_on(client, 'networking.fqdn') }
  let(:server_fqdn) { fact_on(server, 'networking.fqdn') }
  let(:nextserver_fqdn) { fact_on(nextserver, 'networking.fqdn') }

  let(:client_manifest) do
    <<~EOS
      class { 'rsyslog':
        log_servers        => ["#{server_fqdn}"],
        logrotate          => true,
        enable_tls_logging => true,

        # Using pki, but don't enable pki::copy
        pki                => false,
        app_pki_dir        => '/etc/pki/simp-testing/pki',
      }

      # Forward TLS-encrypted
      rsyslog::rule::remote { 'send_the_logs_tls':
        rule => 'prifilt(\\'*.*\\')',
      }
    EOS
  end

  let(:hieradata) do
    <<~EOS
      ---
      iptables::disable : false
      rsyslog::server::enable_firewall : true
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
        log_servers        => ['server-2'],

        # Outgoing logs should not be TLS-encrypted
        # NOTE:  If we need to send to some follow-on servers that are
        #        TLS-enabled and some that are not, will need to use
        #        <host>:<port> format in the rsyslog::rule::remote
        #        to distinguish the two cases, as that 'define' uses
        #        rsyslog::rule::enable_tls_logging to determine the
        #        otherwise unspecified port.
        enable_tls_logging => false,

        tls_tcp_server     => true,
        logrotate          => true,

        # Using pki for our TLS server, but don't enable pki::copy
        pki                => false,
        app_pki_dir        => '/etc/pki/simp-testing/pki',

        trusted_nets       => ['any'],
      }

      class { 'rsyslog::server':
        enable_firewall    => true,
        enable_selinux     => false,
        enable_tcpwrappers => false,
      }

      # Forward plain TCP to our remote log servers
      rsyslog::rule::remote { 'send_the_logs_plain_tcp':
        stream_driver => 'tcp',
        rule => 'prifilt(\\'*.*\\')',
      }

      # Also log in a local, host-named directory

      # Define a dynamic file with an rsyslog template
      # NOTE: puppet doesn't need to manage missing directories in this path;
      #       rsyslog will create them as needed.
      rsyslog::template::string { 'log_everything_by_host':
        string => '/var/log/hosts/%HOSTNAME%/everything.log',
      }

      # Log all messages to the dynamic file we just defined ^^
      rsyslog::rule::local { 'all_the_logs_tls':
        rule      => 'prifilt(\\'*.*\\')',
        dyna_file => 'log_everything_by_host',
      }
    EOS
  end

  let(:nextserver_manifest) do
    <<~EOS
      include 'iptables'
      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      class { 'rsyslog':
        log_servers        => [],
        enable_tls_logging => false,
        tls_tcp_server     => false,
        tcp_server         => true,
        logrotate          => true,

        # Not using pki at all
        pki                => false,

        trusted_nets       => ['any'],
      }

      class { 'rsyslog::server':
        enable_firewall    => true,
        enable_selinux     => false,
        enable_tcpwrappers => false,
      }

      # Define a dynamic file with an rsyslog template
      # NOTE: puppet doesn't need to manage missing directories in this path;
      #       rsyslog will create them as needed.
      rsyslog::template::string { 'log_everything_by_host':
        string => '/var/log/hosts/%HOSTNAME%/everything.log',
      }

      # Log all messages to the dynamic file we just defined ^^
      rsyslog::rule::local { 'all_the_logs_plain_tcp':
        rule      => 'prifilt(\\'*.*\\')',
        dyna_file => 'log_everything_by_host',
      }
    EOS
  end

  context 'client and server configuration' do
    it 'configures first server without errors' do
      set_hieradata_on(server, hieradata)
      apply_manifest_on(server, server_manifest, catch_failures: true)
    end

    it 'configures first server idempotently' do
      apply_manifest_on(server, server_manifest, catch_changes: true)
    end

    it 'configures next server without errors' do
      set_hieradata_on(nextserver, hieradata)
      apply_manifest_on(nextserver, nextserver_manifest, catch_failures: true)
    end

    it 'configures next server idempotently' do
      apply_manifest_on(nextserver, nextserver_manifest, catch_changes: true)
    end

    it 'configures client without errors' do
      apply_manifest_on(client, client_manifest, catch_failures: true)
    end

    it 'configures client idempotently' do
      apply_manifest_on(client, client_manifest, catch_changes: true)
    end
  end

  context 'log forwarding' do
    it 'client should successfully send log messages using TLS to 1st server' do
      on client, 'logger -t FOO TEST-USING-TLS'
      server_remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on server, "test -f #{server_remote_log}"
      on server, "grep TEST-USING-TLS #{server_remote_log}"
    end

    it '1st server should forward messages to non-TLS server using plain TCP' do
      nextserver_remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on nextserver, "test -f #{nextserver_remote_log}"
      on nextserver, "grep TEST-USING-TLS #{nextserver_remote_log}"
    end
  end
end
