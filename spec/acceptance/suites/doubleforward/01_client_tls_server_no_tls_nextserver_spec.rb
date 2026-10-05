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
      compliance_engine::enforcement : ['simp:defaults']
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
        log_servers        => ["#{nextserver_fqdn}"],

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
      # TEMPORARY: keep rsyslogd's stderr, which rsyslog.service discards
      on(server, %(mkdir -p /etc/systemd/system/rsyslog.service.d && printf '[Service]\\nStandardError=journal\\n' > /etc/systemd/system/rsyslog.service.d/zz_debug.conf && systemctl daemon-reload))
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
      set_hieradata_on(client, SIMP_DEFAULTS)
      apply_manifest_on(client, client_manifest, catch_failures: true)
    end

    it 'configures client idempotently' do
      apply_manifest_on(client, client_manifest, catch_changes: true)
    end

    it 'produces a valid rsyslog configuration on all hosts' do
      [server, nextserver, client].each do |host|
        expect_valid_rsyslog_config(host)
      end
    end
  end

  context 'log forwarding' do
    it 'client should successfully send log messages using TLS to 1st server' do
      on client, 'logger -t FOO TEST-USING-TLS'
      server_remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      wait_for_log_message(server, server_remote_log, 'TEST-USING-TLS')
    end

    it '1st server should forward messages to non-TLS server using plain TCP' do
      nextserver_remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      wait_for_log_message(nextserver, nextserver_remote_log, 'TEST-USING-TLS')
    end
  end

  # With TLS enabled globally, one rule can still forward in plain text. The
  # direct copy is marked with its own template: the relayed copy is otherwise
  # identical, and $RepeatedMsgReduction would collapse the two.
  context 'hybrid TLS and plain-text forwarding with use_tls' do
    let(:hybrid_client_manifest) do
      <<~EOS
        #{client_manifest}

        rsyslog::template::string { 'direct_marker':
          string => '<%PRI%>%TIMESTAMP:::date-rfc3339% %HOSTNAME% %syslogtag%DIRECT%msg%\\n',
        }

        # Forward plain text directly to the non-TLS server
        rsyslog::rule::remote { 'send_the_logs_plain_tcp':
          rule     => '$programname == \\'HYBRID\\'',
          dest     => ["#{nextserver_fqdn}"],
          template => 'direct_marker',
          use_tls  => false,
          require  => Rsyslog::Template::String['direct_marker'],
        }
      EOS
    end

    it 'configures the client without errors' do
      apply_manifest_on(client, hybrid_client_manifest, catch_failures: true)
    end

    it 'configures the client idempotently' do
      apply_manifest_on(client, hybrid_client_manifest, catch_changes: true)
    end

    it 'produces a valid rsyslog configuration' do
      expect_valid_rsyslog_config(client)
    end

    it 'writes a plain-text action next to the TLS one' do
      on(client, 'grep -q \'StreamDriver="ptcp"\' /etc/rsyslog.simp.d/10_simp_remote/send_the_logs_plain_tcp.conf')
      on(client, 'grep -q \'StreamDriverMode="1"\' /etc/rsyslog.simp.d/10_simp_remote/send_the_logs_tls.conf')
    end

    it 'delivers over TLS to the TLS server and in plain text directly to the non-TLS server' do
      on client, 'logger -t HYBRID TEST-HYBRID-TLS'

      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      wait_for_log_message(server, remote_log, 'TEST-HYBRID-TLS')
      wait_for_log_message(nextserver, remote_log, "'DIRECT TEST-HYBRID-TLS'")
    end
  end
end
