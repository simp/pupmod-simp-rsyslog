# This test can take a LONG time to run so we need to bump up the global
# timeout
ENV['SIMPTEST_WAIT_FOR_LOG_MAX'] = '600'

require 'spec_helper_acceptance'

test_name 'client -> 2 server with TLS'

describe 'rsyslog class' do

  before(:all) do
    # Ensure that our test doesn't match messages from other tests
    sleep(1)
    @msg_uuid = Time.now.to_f.to_s.gsub('.','_') + '_WITH_TLS'
  end

  let(:client){ only_host_with_role( hosts, 'client' ) }
  let(:client_fqdn){ fact_on( client, 'fqdn' ) }
  let(:servers){ hosts_with_role( hosts, 'server' ) }
  let(:server1_fqdn){ fact_on( servers[0], 'fqdn' ) }
  let(:server2_fqdn){ fact_on( servers[1], 'fqdn' ) }
  let(:failover_servers){ hosts_with_role( hosts, 'failover_server' ) }
  let(:failover_server_fqdn){ fact_on( failover_servers.first, 'fqdn' ) }

  let(:client_manifest_hieradata) {
    {
      'rsyslog::log_servers'        => [server1_fqdn, server2_fqdn],
      'rsyslog::logrotate'          => true,
      'rsyslog::enable_tls_logging' => true,
      'rsyslog::pki'                => false,
      'rsyslog::app_pki_dir'        => '/etc/pki/simp-testing/pki'
    }
  }
  let(:client_manifest) {
    <<-EOS
      include 'rsyslog'

      rsyslog::rule::remote { 'send_the_logs':
        rule => 'prifilt(\\'*.*\\')'
      }
    EOS
  }

  let(:client_failover_hieradata) {
    {
      'rsyslog::log_servers'          => [server1_fqdn, server2_fqdn],
      'rsyslog::failover_log_servers' => [failover_server_fqdn],
      'rsyslog::logrotate'            => true,
      'rsyslog::enable_tls_logging'   => true,
      'rsyslog::pki'                  => false,
      'rsyslog::app_pki_dir'          => '/etc/pki/simp-testing/pki'
    }
  }

  let(:client_failover_small_queue_hieradata) {
    {
      'rsyslog::log_servers'                           => [server1_fqdn, server2_fqdn],
      'rsyslog::failover_log_servers'                  => [failover_server_fqdn],
      'rsyslog::logrotate'                             => true,
      'rsyslog::enable_tls_logging'                    => true,
      'rsyslog::pki'                                   => false,
      'rsyslog::app_pki_dir'                           => '/etc/pki/simp-testing/pki',
      'rsyslog::config::main_msg_queue_high_watermark' => 2,
      'rsyslog::config::main_msg_queue_low_watermark'  => 1
    }
  }

  # This is used for testing the failover queueing
  let(:client_failover_manifest_small_queue) {
    <<-EOS
      include 'rsyslog'

      rsyslog::rule::remote { 'send_the_logs':
        rule                 => 'prifilt(\\'*.*\\')',
        queue_filename       => 'test_queue',
        queue_high_watermark => 2,
        queue_low_watermark  => 1
      }
    EOS
  }

  let(:server_manifest_hieradata) {
    {
      'iptables::disable'                   => false,
      'rsyslog::tcp_server'                 => true,
      'rsyslog::logrotate'                  => true,
      'rsyslog::tls_tcp_server'             => true,
      'rsyslog::pki'                        => false,
      'rsyslog::app_pki_dir'                => '/etc/pki/simp-testing/pki',
      'rsyslog::trusted_nets'               => ['any'],
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
      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any']
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
        rule      => 'prifilt(\\'*.*\\')',
        dyna_file => 'log_everything_by_host'
      }
    EOS
  }

  context 'client -> 2 server without TLS' do
    it 'should configure the servers without errors' do
      (servers + failover_servers).each do |server|
        set_hieradata_on(server, server_manifest_hieradata)
        apply_manifest_on(server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
      end
    end

    it 'should configure the servers idempotently' do
      servers.each do |server|
        apply_manifest_on(server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_changes => true)
      end
    end

    it 'should configure the client without errors' do
      set_hieradata_on(client, client_manifest_hieradata)
      apply_manifest_on(client, client_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    it 'should configure client idempotently' do
      apply_manifest_on(client, client_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    # Default scenario, everything goes to both primary servers
    it 'should successfully send log messages to the primary servers but not the failover server' do
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"
      on client, "logger -t FOO TEST-1-#{@msg_uuid}-MSG"

      servers.each do |server|
        on server, "test -f #{remote_log}"
        on server, "grep TEST-1-#{@msg_uuid}-MSG #{remote_log}"
      end

      failover_servers.each do |server|
        on server, "! grep TEST-1-#{@msg_uuid}-MSG #{remote_log}"
      end
    end

    it 'should be able to enable failover on the client' do
      set_hieradata_on(client, client_failover_hieradata)
      apply_manifest_on(client, client_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
    end

    it 'should successfully failover' do
      failover_server = failover_servers.first
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"

      # Make sure both primary servers are still working properly.
      on client, "logger -t FOO TEST-10-#{@msg_uuid}-MSG"

      servers.each do |server|
        wait_for_log_message(server, remote_log, "TEST-10-#{@msg_uuid}-MSG")
      end

      # Force Failover
      servers.each do |server|
        on server, 'puppet resource service rsyslog ensure=stopped'
      end

      # Give it a couple of seconds
      sleep(2)

      # Log test messages
      (11..20).each do |msg|
        on client, "logger -t FOO TEST-#{msg}-#{@msg_uuid}-MSG"
      end

      # Validate Failover
      wait_for_log_message(failover_server, remote_log, "TEST-11-#{@msg_uuid}-MSG")
      wait_for_log_message(failover_server, remote_log, "TEST-19-#{@msg_uuid}-MSG")

      # Should not log to inactive servers
      servers.each do |server|
        on server, "grep TEST-11-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
        on server, "grep TEST-19-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
      end
    end
  end

  context 'rsyslog queues when all remote servers fail' do
    it 'should queue when no remote systems are available' do
      failover_server = failover_servers.first
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"

      set_hieradata_on(client, client_failover_small_queue_hieradata)
      apply_manifest_on(client, client_failover_manifest_small_queue, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)

      # Make sure logs are still hitting the failover server
      (21..30).each do |msg|
        on client, "logger -t FOO TEST-#{msg}-#{@msg_uuid}-MSG"
      end

      # Validate Failover
      on failover_server, "grep TEST-21-#{@msg_uuid}-MSG #{remote_log}"
      on failover_server, "grep TEST-29-#{@msg_uuid}-MSG #{remote_log}"

      # Make sure that *all* remote logging is stopped
      (failover_servers + servers).each do |server|
        on server, 'puppet resource service rsyslog ensure=stopped'
      end

      sleep(2)

      # Write some new logs and make sure that they don't hit the remote systems
      (31..40).each do |msg|
        on client, "logger -t FOO TEST-#{msg}-#{@msg_uuid}-MSG"
      end

      # Should not log to inactive servers
      (failover_servers + servers).each do |server|
        on server, "grep TEST-31-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
        on server, "grep TEST-39-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
      end

      # Check to see if we now have a queue on disk
      on client, 'test -f /var/spool/rsyslog/test_queue_action\.[[:digit:]][[:digit:]]*'
    end
  end

  # This one is weird. From experience, it seems that rsyslog will only flush
  # the queue when the action that is tied to the queue recovers. This means
  # that the failover system has to come back online before anything will
  # flush.
  context 'rsyslog handles failover recovery' do
    it 'should flush the queue when the last failover server recovers' do
      failover_server = failover_servers.last
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"

      # Let Puppet restart everything properly on the failover server and give
      # it a couple of seconds to recover.
      apply_manifest_on(failover_server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
      sleep(2)

      # See if the queue has flushed properly
      # Note: The queue file remains on the system, so we need to check the
      # failover server for content.
      # Details: http://blog.gerhards.net/2013/07/rsyslog-why-disk-assisted-queues-keep.html

      # Messages should exist on the failover server
      # Sometimes this can take quite a while...
      # Between 20 and 30 Seconds seems to be about the norm for a full flush
      wait_for_log_message(failover_server, remote_log, "TEST-31-#{@msg_uuid}-MSG")
      wait_for_log_message(failover_server, remote_log, "TEST-39-#{@msg_uuid}-MSG")
    end
  end

  context 'rsyslog handles primary server recovery' do
    it 'should log to the primary servers when they recover' do
      remote_log = "/var/log/hosts/#{client_fqdn}/everything.log"

      servers.each do |server|
        apply_manifest_on(server, server_manifest, :hiera_config => client.puppet['hiera_config'], :catch_failures => true)
      end
      # Let the logs start flowing again
      sleep(2)

      (41..50).each do |msg|
        on client, "logger -t FOO TEST-#{msg}-#{@msg_uuid}-MSG"
      end

      # Sometimes this can take a while to flush
      servers.each do |server|
        wait_for_log_message(server, remote_log, "TEST-41-#{@msg_uuid}-MSG")
        wait_for_log_message(server, remote_log, "TEST-50-#{@msg_uuid}-MSG")
      end

      # Should not log to inactive failover servers
      failover_servers.each do |server|
        on server, "grep TEST-41-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
        on server, "grep TEST-49-#{@msg_uuid}-MSG #{remote_log}", :acceptable_exit_codes => [1,2]
      end
    end
  end
end
