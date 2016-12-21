require 'spec_helper_acceptance'

test_name 'rsyslog class'

describe 'rsyslog class' do
  package_name = 'rsyslog'
  if fact('osfamily') == 'RedHat' && fact('operatingsystemmajrelease') == '6'
    package_name = 'rsyslog7'
  end

  let(:client){ only_host_with_role( hosts, 'client' ) }
  let(:manifest) {
    <<-EOS
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

      rsyslog::rule::local { '0_default_sudosh':
        rule            => '$programname == \\'sudosh\\'',
        dyna_file       => 'sudosh_template',
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

  context 'default parameters (no pki)' do
    # Using puppet_apply as a helper
    it 'should work with no errors' do
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

    it 'should add user-specified rules' do
      apply_manifest_on(client, manifest_plus_rules, :catch_failures => true)

      # verify files for user-specified rules exist
      on client, "test -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf"
      on client, "test -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf"
      on client, "test -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf"
      on client, "test -f /etc/rsyslog.simp.d/99_simp_local/0_default_sudosh.conf"
      on client, "test -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf"
      on client, "test -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf"
    end

    it 'should remove OBE user-specified rules' do
      apply_manifest_on(client, manifest, {:catch_failures => true})

      # verify files for OBE user-specified rules have been removed
      on client, "test ! -f /etc/rsyslog.simp.d/06_simp_console/0_default_emerg.conf"
      on client, "test ! -f /etc/rsyslog.simp.d/05_simp_data_sources/openldap_audit.conf"
      on client, "test ! -f /etc/rsyslog.simp.d/07_simp_drop_rules/audispd.conf"
      on client, "test ! -f /etc/rsyslog.simp.d/99_simp_local/0_default_sudosh.conf"
      on client, "test ! -f /etc/rsyslog.simp.d/20_simp_other/aide_report.conf"
      on client, "test ! -f /etc/rsyslog.simp.d/10_simp_remote/all_forward.conf"
    end

    if fact('operatingsystemmajrelease') > '6'
      it 'should see entries from the journal in /var/log/messages' do
        on client, "echo someeasytosearchforstring | systemd-cat -p notice -t acceptance"

        on client, "grep someeasytosearchforstring /var/log/messages"
      end
    end

  end
end
