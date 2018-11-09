require 'spec_helper_acceptance'
require 'json'

test_name 'rsyslog class'

describe 'rsyslog class' do

  package_name = 'rsyslog'
  if fact('osfamily') == 'RedHat' && fact('operatingsystemmajrelease') == '6'
    package_name = 'rsyslog7'
  end

  let(:client){ only_host_with_role( hosts, 'client' ) }
  let(:manifest) {
    <<-EOS
      # Turns off firewalld in EL7
      include 'iptables'

      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      class { 'rsyslog': pki  => false }
    EOS
  }

  let(:manifest_plus_rules) {
    <<-EOS
      class { 'rsyslog': pki  => false }

      rsyslog::rule::console { '0_default_emerg':
        rule  => 'prifilt(\\'*.emerg\\')',
        users => ['*']
      }

      rsyslog::rule::data_source { 'openldap_audit':
        rule    => "
input(type=\\"imfile\\"
  File=\\"/var/log/secure\\"
  Tag=\\"slapd_audit\\"
  Facility=\\"local6\\"
  Severity=\\"notice\\"
)"
      }

      rsyslog::rule::drop { 'audispd':
        rule   => '$programname == \\'audispd\\''
      }

      rsyslog::rule::local { '0_default_custom_test':
        rule            => '$programname == \\'custom_test\\'',
        dyna_file       => 'custom_test_template',
        stop_processing => true
      }

      rsyslog::rule::other { 'aide_report':
        rule    =>
"input(type=\\"imfile\\"
  File=\\"/var/log/secure\\"
  Tag=\\"tag_aide_report\\"
  StateFile=\\"aide_report\\"
  Severity=\\"warning\\"
  Facility=\\"local6\\"
)"
      }

      rsyslog::rule::remote { 'all_forward':
        rule      => 'prifilt(\\'*.*\\')',
        dest      => ['1.1.1.1', '2.2.2.2'],
        dest_type => 'tcp'
      }

    EOS
  }

  let(:another_drop_rule) {
    <<-EOS
      rsyslog::rule::drop { '1_drop_openldap_passwords':
        rule => '$syslogtag == \\'slapd_audit\\' and $msg contains \\'Password:: \\''
      }

    EOS
  }

  context 'default parameters (no pki)' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
      apply_manifest_on(client, manifest, :catch_failures => true)

      # requires 2 runs to be idempotent on centos6
      apply_manifest_on(client, manifest, :catch_failures => true)
      # reboot to apply auditd changes
      # shell( 'shutdown -r now', { :expect_connection_failure => true } )
    end

    it 'should be idempotent' do
      apply_manifest_on(client, manifest, {:catch_changes => true})
    end

    describe package(package_name) do
      it { is_expected.to be_installed }
    end

    describe service('rsyslog') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end


    it 'should ensure rsyslog.service starts after network.target and network-online.target' do
      facts = JSON.load(on(client, 'puppet facts').stdout)
      if facts['values']['systemd']
        # client uses systemd
        # following 3 lines for debug
        on client, 'rpm -q rsyslog'
        on client, 'cat /usr/lib/systemd/system/rsyslog.service'
        on client, 'systemctl show rsyslog.service'

        on client, 'cat /etc/systemd/system/rsyslog.service.d/unit.conf'

        [ 'Wants', 'After' ].each do |req|
          result = on(client, "systemctl show rsyslog.service | grep ^#{req}=").stdout
          expect(result).to match(/network.target/)
          expect(result).to match(/network-online.target/)
        end
      else
        puts "Skipping test on #{client.name}, which does not use systemd"
      end
    end

    it 'should collect iptables log messages in /var/log/iptables.log' do
      # Trigger an iptables block event for the logs
      require 'socket'
      require 'timeout'

      begin
        Timeout::timeout(5) do
          begin
            s = TCPSocket.new(client.ip, 44)
            sleep(1)
            s.close
          rescue Errno::ECONNREFUSED, Errno::EHOSTUNREACH
            # This should be rejected
          end
        end
      rescue Timeout::Error
      end

      # kern facility messages cannot be created by a user via logger,
      # because the facility is automatically changed to user. So, the
      # only way to test this is to cause an actual iptables drop.
      # TODO:  The code below should be replaced with use of the actual
      #   iptables modules, a new drop rule for some port, and then nc
      #   to try to open a connection to that port.
      #
      # Set up iptables to disallow icmp requests
      on client, 'iptables --list-rules'
      on client, 'iptables -N LOG_AND_DROP'
      on client, 'iptables -A LOG_AND_DROP -j LOG --log-prefix "IPT:"'
      on client, 'iptables -A LOG_AND_DROP -j DROP'
      on client, 'iptables -A INPUT -p icmp -m icmp --icmp-type 8 -j LOG_AND_DROP'
      on client, 'ping -c 1 `facter ipaddress`', :accept_all_exit_codes => true

      check = on(client, "grep -l 'IPT:' /var/log/iptables.log").stdout.strip
      expect(check).to eq('/var/log/iptables.log')

      # clean up iptables rules to allow later tests to start with a clean slate
      on client, 'iptables --delete LOG_AND_DROP -j LOG --log-prefix "IPT:"'
      on client, 'iptables --delete LOG_AND_DROP -j DROP'
      on client, 'iptables --delete INPUT -p icmp -m icmp --icmp-type 8 -j LOG_AND_DROP'
      on client, 'iptables -X LOG_AND_DROP'
      on client, 'iptables --list-rules'
    end

    it 'should collect authpriv, local6, and local5 log messages in /var/log/secure' do
      on client, 'logger -p authpriv.warning -t auth LOCAL_ONLY_AUTHPRIV_ANY_LOG'
      on client, 'logger -t crond LOCAL_ONLY_CROND_LOG'
      on client, 'logger -p local5.notice -t id1 LOCAL_ONLY_LOCAL5_ANY_LOG'
      on client, 'logger -p local6.info -t id2 LOCAL_ONLY_LOCAL6_ANY_LOG'

      [ 'LOCAL_ONLY_AUTHPRIV_ANY_LOG',
        'LOCAL_ONLY_LOCAL5_ANY_LOG',
        'LOCAL_ONLY_LOCAL6_ANY_LOG',
      ].each do |message|
          check = on(client, "grep -l '#{message}' /var/log/secure").stdout.strip
          expect(check).to eq('/var/log/secure')
      end
    end

    it 'should add user-specified rules and restart rsyslog service' do
      result = apply_manifest_on(client, manifest_plus_rules, :catch_failures => true)

      # verify files for user-specified rules exist
      on client, "test -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf"
      on client, "test -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf"
      on client, "test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf"
      on client, "test -f /etc/rsyslog.simp.d/99_simp_local/0_default_custom_test.conf"
      on client, "test -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf"
      on client, "test -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf"

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'should restart rsyslog service after another rule is added to an existing subdirectory' do
      result = apply_manifest_on(client, manifest_plus_rules + another_drop_rule, :catch_failures => true)
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/1_drop_openldap_passwords.conf'

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from 1 event"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'should remove OBE-user-specified rule from an subdirectory with other rules and restart rsyslog service' do
      result = apply_manifest_on(client, manifest_plus_rules, :catch_failures => true)
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test ! -f /etc/rsyslog.simp.d/07_simp_drop_rules/1_drop_openldap_passwords.conf'

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from 1 event"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'should remove OBE user-specified rules and resulting empty subdirectories' do
      apply_manifest_on(client, manifest, {:catch_failures => true})

      # verify files for OBE user-specified rules have been removed
      on client, 'test ! -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/06_simp_console'
      on client, 'test ! -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/05_simp_data_sources'
      on client, 'test ! -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/07_simp_drop_rules'
      on client, 'test ! -f /etc/rsyslog.simp.d/99_simp_local/0_default_custom_test.conf'
      on client, 'test -d /etc/rsyslog.simp.d/99_simp_local'  # another rule still there
      on client, 'test ! -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/20_simp_other'
      on client, 'test ! -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/10_simp_remote'
    end

    if fact('operatingsystemmajrelease') > '6'
      it 'should see entries from the journal in /var/log/messages' do
        on client, "echo someeasytosearchforstring | systemd-cat -p notice -t acceptance"

        on client, "grep someeasytosearchforstring /var/log/messages"
      end
    end

  end
end
