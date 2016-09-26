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
require 'timeout'
def wait_for_log_message(
    host,
    log,
    message,
    max_wait_seconds = (ENV['SIMPTEST_WAIT_FOR_LOG_MAX'] ? ENV['SIMPTEST_WAIT_FOR_LOG_MAX'].to_f : 60.0),
    interval_sec = (ENV['SIMPTEST_LOG_CHECK_INTERVAL'] ? ENV['SIMPTEST_LOG_CHECK_INTERVAL'].to_f : 1.0)
  )
  result = nil
  Timeout::timeout(max_wait_seconds) do
    while true
      result = on host, "grep #{message} #{log}", :accept_all_exit_codes => true
      return if result.exit_code == 0
      sleep(interval_sec)
    end
  end
rescue Timeout::Error => e
  error_msg = "Failed to find '#{message}' in #{log} on #{host} within #{max_wait_seconds} seconds:\n"
  error_msg += "\texit_code = #{result.exit_code}\n"
  error_msg += "\tstdout = \"#{result.stdout}\"\n" unless result.stdout.nil? or result.stdout.strip.empty?
  error_msg += "\tstderr = \"#{result.stderr}\"" unless result.stderr.nil? or result.stderr.strip.empty?
  fail error_msg
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

  # Readable test descriptions
  c.formatter = :documentation

  # Configure all nodes in nodeset
  c.before :suite do
    begin
      # Install modules and dependencies from spec/fixtures/modules
      copy_fixture_modules_to( hosts )
      begin
        server = only_host_with_role(hosts, 'server')
      rescue ArgumentError =>e
        server = only_host_with_role(hosts, 'default')
      end

      # Generate and install PKI certificates on each SUT
      Dir.mktmpdir do |cert_dir|
        run_fake_pki_ca_on(server, hosts, cert_dir )
        hosts.each{ |sut| copy_pki_to( sut, cert_dir, '/etc/pki/simp-testing' )}
      end

      # add PKI keys
      copy_keydist_to(server)
    rescue StandardError, ScriptError => e
      if ENV['PRY']
        require 'pry'; binding.pry
      else
        raise e
      end
    end
  end
end
