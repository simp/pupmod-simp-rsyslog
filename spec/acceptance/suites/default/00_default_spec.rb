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
  # even though nothing rsyslog manages exists yet. The preview enforces
  # `simp:defaults`, so it covers the configuration resources and not just the
  # package, and checks that specific changes are reported.
  #
  # We noop a bare `include` rather than the suite `manifest` above: that manifest
  # also declares a troubleshooting `iptables::listen::tcp_stateful` SSH rule,
  # which under --noop trips a simp_firewalld provider bug on EL8 --
  # `firewall-offline-cmd --zone 99_simp --list-services` returns 112
  # (INVALID_ZONE) because the zone a noop-suppressed resource would create does
  # not exist yet, so the run errors (exit 4).
  # See simp/pupmod-simp-simp_firewalld#106.
  context 'in noop mode from a clean state with simp:defaults enforced' do
    let(:noop_manifest) { "include 'rsyslog'" }

    before(:context) do
      on(hosts, 'puppet resource package rsyslog ensure=absent')
      hosts.each { |host| set_hieradata_on(host, SIMP_DEFAULTS) }
    end

    it 'applies without errors in noop mode and previews the configuration' do
      hosts.each do |host|
        result = apply_manifest_on(host, noop_manifest, catch_failures: true, noop: true)
        expect(result.output).to match(%r{File\[/etc/rsyslog\.conf\]/ensure: current_value '?absent'?, should be '?file'? \(noop\)})
        expect(result.output).to match(%r{File_line\[rsyslog 10_global preserveFQDN\]/ensure: .*\(noop\)})
        expect(result.output).to match(%r{Service\[rsyslog\]/ensure: .*\(noop\)})
      end
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

  context 'with a bare include' do
    before(:context) do
      set_hieradata_on(client, {})
    end

    it 'installs the package without errors' do
      apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest_on(client, "include 'rsyslog'", catch_changes: true)
    end

    it 'leaves the package configuration untouched' do
      # rpm -V prints nothing for files that match the package
      expect(on(client, 'rpm -V rsyslog', accept_all_exit_codes: true).stdout).not_to match(%r{/etc/rsyslog\.conf|/etc/sysconfig/rsyslog})
      on(client, 'test ! -e /etc/rsyslog.simp.d')
      on(client, 'test ! -e /etc/systemd/system/rsyslog.service.d/simp_limits.conf')
    end
  end

  # The core principle: a setting can be enforced alone, a later run that no
  # longer sets it leaves it in place, and `absent` removes it.
  context 'with one setting enforced alone on the package rsyslog.conf' do
    let(:setting_file) { '/etc/rsyslog.simp.d/00_simp_pre_logging/10_global.conf' }

    it 'applies the setting' do
      set_hieradata_on(client, { 'rsyslog::config::net_enable_dns' => false, 'rsyslog::restart_on_change' => true })
      on(client, 'systemctl start rsyslog')
      result = apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)
      expect(result.stdout).to include("Exec[rsyslog restart_on_change]: Triggered 'refresh'")

      on(client, %(grep -qx '  net.enableDNS="off"' #{setting_file}))
      on(client, "grep -qx '\\$IncludeConfig /etc/rsyslog.simp.d/\\*.conf' /etc/rsyslog.conf")
      expect_valid_rsyslog_config(client)
    end

    it 'keeps the setting when a later run no longer sets it' do
      set_hieradata_on(client, {})
      apply_manifest_on(client, "include 'rsyslog'", catch_changes: true)
      on(client, %(grep -qx '  net.enableDNS="off"' #{setting_file}))
    end

    it 'removes the setting when set to absent' do
      set_hieradata_on(client, { 'rsyslog::config::net_enable_dns' => 'absent' })
      apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)
      on(client, "! grep -q net.enableDNS #{setting_file}")
      expect_valid_rsyslog_config(client)
    end
  end

  context 'with simp:defaults enforced (no pki)' do
    it 'works with no errors' do
      set_hieradata_on(client, SIMP_DEFAULTS)
      apply_manifest_on(client, manifest, catch_failures: true)
    end

    it 'is idempotent' do
      apply_manifest_on(client, manifest, { catch_changes: true })
    end

    it 'produces a valid rsyslog configuration' do
      expect_valid_rsyslog_config(client)
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
