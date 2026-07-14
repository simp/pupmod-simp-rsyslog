require 'spec_helper_acceptance'
require 'json'

test_name 'rsyslog class'

describe 'rsyslog class' do
  let(:client) { only_host_with_role(hosts, 'client') }
  let(:manifest) do
    <<~EOS
      include 'iptables'

      iptables::listen::tcp_stateful { 'ssh':
        dports       => 22,
        trusted_nets => ['any'],
      }

      class { 'rsyslog': pki  => false }
    EOS
  end

  let(:manifest_plus_rules) do
    <<~EOS
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
        rule   => '$programname == \\'audispd\\'',
      }

      rsyslog::rule::local { '0_default_custom_test':
        rule            => '$programname == \\'custom_test\\'',
        dyna_file       => 'custom_test_template',
        stop_processing => true,
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
        dest_type => 'tcp',
      }

    EOS
  end

  let(:another_drop_rule) do
    <<~EOS
      rsyslog::rule::drop { '1_drop_openldap_passwords':
        rule => '$syslogtag == \\'slapd_audit\\' and $msg contains \\'Password:: \\''
      }

    EOS
  end

  # Exercise noop from a clean (uninstalled) state: on a fresh node the Sicura
  # console previews the module with `puppet apply --noop`, which must not error
  # even though nothing rsyslog manages exists yet. Real idempotence is covered
  # by the applies below. A post-convergence noop check is deliberately omitted:
  # `puppet apply --noop --detailed-exitcodes` always exits 0, so it could never
  # fail and would test nothing.
  #
  # We noop a bare `include` rather than the suite `manifest` above: that manifest
  # also declares a troubleshooting `iptables::listen::tcp_stateful` SSH rule,
  # which under --noop trips a simp_firewalld provider bug on EL8 --
  # `firewall-offline-cmd --zone 99_simp --list-services` returns 112
  # (INVALID_ZONE) because the zone a noop-suppressed resource would create does
  # not exist yet, so the run errors (exit 4). The console previews the module
  # class itself (firewall default-off), so a bare include is both the
  # representative subject and free of that unrelated rule.
  # See simp/pupmod-simp-simp_firewalld#106.
  context 'in noop mode from a clean state' do
    let(:noop_manifest) { "include 'rsyslog'" }

    before(:context) do
      on(hosts, 'puppet resource package rsyslog ensure=absent')
    end

    it 'applies without errors in noop mode' do
      apply_manifest_on(hosts, noop_manifest, catch_failures: true, noop: true)
    end
  end

  context 'fix static host name' do
    hosts.each do |host|
      it "ensures static host name matches FQDN fact on #{host}" do
        fqdn = fact_on(host, 'networking.fqdn')
        on(host, "hostnamectl set-hostname --static #{fqdn}")
      end
    end
  end

  context 'default parameters (no pki)' do
    it 'works with no errors' do
      apply_manifest_on(client, manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest_on(client, manifest, { catch_changes: true })
    end

    it 'has rsyslog package installed' do
      result = on(client, 'puppet resource package rsyslog').stdout
      expect(result).not_to match(%r{ensure\s*=>\s*'purged'})
    end

    it 'has rsyslog service running and enabled' do
      result = on(client, 'puppet resource service rsyslog').stdout
      expect(result).to match(%r{ensure\s*=>\s*'running'})
      expect(result).to match(%r{enable\s*=>\s*'true'})
    end

    it 'ensures rsyslog.service starts after network.target and network-online.target' do
      rsyslogd_version = pfact_on(client, 'rsyslogd.version')
      if rsyslogd_version == '8.24.0'
        # following 3 lines for debug
        on client, 'rpm -q rsyslog'
        on client, 'cat /usr/lib/systemd/system/rsyslog.service'
        on client, 'systemctl show rsyslog.service'

        on client, 'cat /etc/systemd/system/rsyslog.service.d/unit.conf'

        [ 'Wants', 'After' ].each do |req|
          result = on(client, "systemctl show rsyslog.service | grep ^#{req}=").stdout
          expect(result).to match(%r{network.target})
          expect(result).to match(%r{network-online.target})
        end
      else
        puts "Skipping test on #{client.name}: systemd override file not needed" # rubocop:disable RSpec/Output
      end
    end

    it 'collects firewall log messages' do
      skip('firewall tests are well exercised via simp/simp_rsyslog')
    end

    it 'collects authpriv, local6, and local5 log messages in /var/log/secure' do
      on client, 'logger -p authpriv.warning -t auth LOCAL_ONLY_AUTHPRIV_ANY_LOG'
      on client, 'logger -t crond LOCAL_ONLY_CROND_LOG'
      on client, 'logger -p local5.notice -t id1 LOCAL_ONLY_LOCAL5_ANY_LOG'
      on client, 'logger -p local6.info -t id2 LOCAL_ONLY_LOCAL6_ANY_LOG'

      [ 'LOCAL_ONLY_AUTHPRIV_ANY_LOG',
        'LOCAL_ONLY_LOCAL5_ANY_LOG',
        'LOCAL_ONLY_LOCAL6_ANY_LOG'].each do |message|
        check = on(client, "grep -l '#{message}' /var/log/secure").stdout.strip
        expect(check).to eq('/var/log/secure')
      end
    end

    it 'adds user-specified rules and restart rsyslog service' do
      result = apply_manifest_on(client, manifest_plus_rules, catch_failures: true)

      # verify files for user-specified rules exist
      on client, 'test -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf'
      on client, 'test -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf'
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test -f /etc/rsyslog.simp.d/99_simp_local/0_default_custom_test.conf'
      on client, 'test -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf'
      on client, 'test -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf'

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'restarts rsyslog service after another rule is added to an existing subdirectory' do
      result = apply_manifest_on(client, manifest_plus_rules + another_drop_rule, catch_failures: true)
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/1_drop_openldap_passwords.conf'

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from 1 event"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'removes OBE-user-specified rule from an subdirectory with other rules and restart rsyslog service' do
      result = apply_manifest_on(client, manifest_plus_rules, catch_failures: true)
      on client, 'test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test ! -f /etc/rsyslog.simp.d/07_simp_drop_rules/1_drop_openldap_passwords.conf'

      refresh_msg = "Stage[main]/Rsyslog::Service/Service[rsyslog]: Triggered 'refresh' from 1 event"
      expect(result.stdout).to match(Regexp.escape(refresh_msg))
    end

    it 'removes OBE user-specified rules and resulting empty subdirectories' do
      apply_manifest_on(client, manifest, { catch_failures: true })

      # verify files for OBE user-specified rules have been removed
      on client, 'test ! -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/06_simp_console'
      on client, 'test ! -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/05_simp_data_sources'
      on client, 'test ! -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/07_simp_drop_rules'
      on client, 'test ! -f /etc/rsyslog.simp.d/99_simp_local/0_default_custom_test.conf'
      on client, 'test -d /etc/rsyslog.simp.d/99_simp_local' # another rule still there
      on client, 'test ! -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/20_simp_other'
      on client, 'test ! -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf'
      on client, 'test ! -d /etc/rsyslog.simp.d/10_simp_remote'
    end

    it 'sees entries from the journal in /var/log/messages' do
      on client, 'echo someeasytosearchforstring | systemd-cat -p notice -t acceptance'

      retry_on client, 'grep someeasytosearchforstring /var/log/messages'
    end
  end
end
