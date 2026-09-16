require 'beaker-rspec'
require 'tmpdir'
require 'yaml'
require 'simp/beaker_helpers'
include Simp::BeakerHelpers

# Wait up to max_wait_seconds for a message to be logged on a host or fail
# @param [String] host Name of test server on which the log file resides
# @param [String] log Fully qualified path to log on the test server
# @param [String] message Message to search for within the test server's log
# @param [Float]  max_wait_seconds Maximum number of seconds to wait for the
#                                  message to be found in the log before failing
# @param [Float]  interval_sec Interval in seconds between log checks
#
# TODO move to Simp::BeakerHelpers
# Validate the complete rsyslog configuration on a host with `rsyslogd -N1`.
#
# Catches invalid or removed configuration parameters (e.g. #161) that a
# running rsyslogd only reports as startup errors while otherwise appearing
# to work.
#
# `rsyslogd -N1` exits non-zero for warnings as well as errors, so
# known-benign warnings are filtered out before failing.
def expect_valid_rsyslog_config(host)
  result = on(host, 'rsyslogd -N1', accept_all_exit_codes: true)
  return if result.exit_code == 0

  issues = result.output.lines.map(&:strip).reject do |line|
    line.empty? ||
      line.include?('config validation run') ||
      # this module always preloads imfile for rsyslog::rule::data_source,
      # so rsyslog warns when no imfile inputs are configured
      line.include?('imfile: no files configured to be monitored')
  end

  expect(issues).to be_empty, "rsyslogd -N1 exited #{result.exit_code}:\n#{result.output}"
end

require 'timeout'
def wait_for_log_message(
  host,
  log,
  message,
  max_wait_seconds = (ENV['SIMPTEST_WAIT_FOR_LOG_MAX'] ? ENV['SIMPTEST_WAIT_FOR_LOG_MAX'].to_f : 60.0),
  interval_sec = (ENV['SIMPTEST_LOG_CHECK_INTERVAL'] ? ENV['SIMPTEST_LOG_CHECK_INTERVAL'].to_f : 1.0)
)
  result = nil
  Timeout.timeout(max_wait_seconds) do
    loop do
      result = on host, "grep #{message} #{log}", accept_all_exit_codes: true
      return if result.exit_code == 0
      sleep(interval_sec)
    end
  end
rescue Timeout::Error
  error_msg = "Failed to find '#{message}' in #{log} on #{host} within #{max_wait_seconds} seconds:\n"
  error_msg += "\texit_code = #{result.exit_code}\n"
  error_msg += "\tstdout = \"#{result.stdout}\"\n" unless result.stdout.nil? || result.stdout.strip.empty?
  error_msg += "\tstderr = \"#{result.stderr}\"" unless result.stderr.nil? || result.stderr.strip.empty?
  raise error_msg
end

# Block until a client's failover forwarding action is proven to be delivering
# to the failover server.
#
# rsyslog only suspends the omfwd action for a dead TCP peer after at least
# one send to that peer has already failed (the first write after a peer
# closes is silently swallowed by the socket), and a failover action
# (action.execOnlyWhenPreviousIsSuspended) only engages once the preceding
# action is suspended.  Messages logged inside that detection window are
# expected to be lost, so tests must not assert on them: this helper burns
# through the window with sacrificial TRIGGER messages and returns once the
# last of them arrives on the failover server.
def wait_for_failover_to_engage(client, failover_server, remote_log, msg_uuid, num_triggers = 5)
  (1..num_triggers).each do |num|
    on client, "logger -t FOO TRIGGER-#{num}-#{msg_uuid}-MSG"
    sleep(1)
  end
  wait_for_log_message(failover_server, remote_log, "TRIGGER-#{num_triggers}-#{msg_uuid}-MSG")
end

# Block until a client's forwarding action to a recovered server has resumed.
#
# rsyslog retries a suspended action lazily — when a message arrives for it
# and the (backed-off) resume interval has elapsed.  Messages logged before
# that retry fires are dropped for the action (failing over instead), so
# tests must not assert that they reach the recovered server: this helper
# sends sacrificial RESUME messages until one provably arrives on it.
def wait_for_forwarding_to_resume(client, server, remote_log, msg_uuid, max_rounds = 30)
  resumed = (1..max_rounds).any? do |num|
    on client, "logger -t FOO RESUME-#{num}-#{msg_uuid}-MSG"
    sleep(3)
    result = on server, "grep -E 'RESUME-[0-9]+-#{msg_uuid}-MSG' #{remote_log}", accept_all_exit_codes: true
    result.exit_code == 0
  end
  raise "Forwarding from #{client} to #{server} did not resume within #{max_rounds} attempts" unless resumed
end

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

RSpec.configure do |c|
  # ensure that environment OS is ready on each host
  fix_errata_on hosts

  # Detect cases in which no examples are executed (e.g., nodeset does not
  # have hosts with required roles)
  c.fail_if_no_examples = true

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    # Install modules and dependencies from spec/fixtures/modules
    copy_fixture_modules_to(hosts)
    begin
      server = only_host_with_role(hosts, 'server')
    rescue ArgumentError => e
      server = only_host_with_role(hosts, 'default')
    end

    # Generate and install PKI certificates on each SUT
    Dir.mktmpdir do |cert_dir|
      run_fake_pki_ca_on(server, hosts, cert_dir)
      hosts.each { |sut| copy_pki_to(sut, cert_dir, '/etc/pki/simp-testing') }
    end

    # add PKI keys
    copy_keydist_to(server)
  rescue StandardError, ScriptError => e
    raise e unless ENV['PRY']
    require 'pry'
    binding.pry # rubocop:disable Lint/Debugger
  end
end
