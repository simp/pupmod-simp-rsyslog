require 'spec_helper'
require_relative '../lib/rendered_config'

describe 'rsyslog' do
  let(:pre_logging) { '/etc/rsyslog.simp.d/00_simp_pre_logging' }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        custom = os_facts.dup

        custom[:rsyslogd] = { 'version' => '8.2102.0' }
        custom[:memory][:system][:total_bytes] = 268_435_456
        custom[:processors][:count] = 4

        # Contexts that differ only by `let(:hieradata)` are otherwise
        # indistinguishable to rspec-puppet's fact-keyed catalogue cache,
        # because `custom_hiera` normally only travels through the global
        # `RSpec.configuration.default_facts` mutation in spec_helper.rb
        # (simp/pupmod-simp-rsyslog#211, simp/puppetsync#90).  Pin it into
        # this example's facts so each context compiles its own catalogue
        # with the correct hiera layer.
        custom[:custom_hiera] = defined?(hieradata) ? hieradata.tr(':', '_') : 'rsyslog'

        custom
      end

      let(:rendered) { RenderedConfig.files(catalogue) }

      context 'with default parameters (bare include)' do
        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('rsyslog::install').that_comes_before('Class[rsyslog::config]') }
        it { is_expected.to contain_class('rsyslog::service').that_subscribes_to('Class[rsyslog::config]') }
        it { is_expected.to contain_package('rsyslog.x86_64').with_ensure('installed') }
        it { is_expected.to contain_package('rsyslog.i386').with_ensure('absent') }

        it 'declares nothing but the packages' do
          declared = catalogue.resources.map(&:type).uniq - ['Class', 'Stage', 'Node', 'Package']
          expect(declared).to be_empty
        end

        it { is_expected.not_to contain_package('rsyslog-gnutls') }
        it { is_expected.not_to contain_service('rsyslog') }
      end

      context 'without the facts that only exist once rsyslog is installed' do
        let(:facts) do
          custom = os_facts.dup
          custom.delete(:rsyslogd)
          custom[:custom_hiera] = 'replace_rsyslog_conf'
          custom
        end

        it { is_expected.to compile.with_all_deps }
      end

      context 'with service_ensure and service_enable set' do
        let(:params) { { service_ensure: 'running', service_enable: true } }

        it {
          is_expected.to contain_service('rsyslog').with(
            ensure: 'running',
            enable: true,
            hasrestart: true,
            hasstatus: true,
          )
        }
        it { is_expected.not_to contain_exec('rsyslog restart_on_change') }
      end

      context 'with only service_enable set' do
        let(:params) { { service_enable: false } }

        it { is_expected.to contain_service('rsyslog').with_enable(false).without_ensure }
      end

      context 'with the deprecated rsyslog::service::enable set' do
        let(:hieradata) { 'service_enable_deprecated' }

        it { is_expected.to contain_service('rsyslog').with(ensure: 'stopped', enable: false) }
      end

      context 'with restart_on_change set and the service unmanaged' do
        let(:params) { { restart_on_change: true } }
        let(:hieradata) { 'single_setting' }

        it { is_expected.not_to contain_service('rsyslog') }
        it {
          is_expected.to contain_exec('rsyslog restart_on_change').with(
            command: 'systemctl try-restart rsyslog.service',
            refreshonly: true,
          )
        }
        it { is_expected.to contain_file_line('rsyslog 10_global net.enableDNS').that_notifies('Class[rsyslog::service]') }
      end

      context 'with restart_on_change and service management set' do
        let(:params) { { restart_on_change: true, service_ensure: 'running' } }

        it { is_expected.to contain_service('rsyslog') }
        it { is_expected.not_to contain_exec('rsyslog restart_on_change') }
      end

      context 'with replace_rsyslog_conf set' do
        let(:hieradata) { 'replace_rsyslog_conf' }

        it { is_expected.to compile.with_all_deps }

        it {
          is_expected.to contain_file('/etc/rsyslog.conf').with_content(<<~EOM)
            # This file is managed by Puppet (simp/rsyslog module).
            # Any changes will be overwritten.
            $IncludeConfig /etc/rsyslog.simp.d/*.conf
          EOM
        }

        it { is_expected.not_to contain_file_line('rsyslog rsyslog.conf include rule_dir') }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d').with_ensure('directory').without_purge }
        it { is_expected.to contain_file('/etc/rsyslog.d/README_SIMP.conf').with_mode('0640') }
        it { is_expected.to contain_rsyslog__rule('09_failover_hack/failover_hack.conf') }
        it { is_expected.not_to contain_rsyslog__rule('99_simp_local/ZZ_default.conf') }
        it { is_expected.not_to contain_service('rsyslog') }

        it 'loads the input modules that a replaced rsyslog.conf needs, and nothing else' do
          expect(rendered).to eq(
            '30_imklog.conf' => "module(load=\"imklog\"\n)\n",
            '31_imuxsock.conf' => "module(load=\"imuxsock\"\n)\n",
            '32_imjournal.conf' => "module(load=\"imjournal\"\n  StateFile=\"imjournal.state\"\n)\n",
            '33_imfile.conf' => "module(load=\"imfile\"\n)\n",
          )
        end

        it { is_expected.to contain_file("#{pre_logging}/31_imuxsock.conf").with_replace(false) }
        it { is_expected.to contain_file_line('rsyslog 32_imjournal StateFile').with_replace(false) }
      end

      context 'with replace_rsyslog_conf and read_journald=false' do
        let(:hieradata) { 'replace_rsyslog_conf' }
        let(:params) { { read_journald: false } }

        it { is_expected.to contain_file("#{pre_logging}/32_imjournal.conf").with_ensure('absent') }
      end

      context 'with custom_conf_content set' do
        let(:hieradata) { 'custom_conf_content' }

        it {
          is_expected.to contain_file('/etc/rsyslog.conf').with_content(<<~EOM)
            # This file is managed by Puppet (simp/rsyslog module).
            # Any changes will be overwritten.
            $IncludeConfig /etc/rsyslog.simp.d/*.conf
            $WorkDirectory /var/spool/rsyslog
          EOM
        }
      end

      context 'including the rsyslog.d directory' do
        let(:hieradata) { 'include_rsyslog_d' }

        it {
          is_expected.to contain_rsyslog__rule('15_include_default_rsyslog/include_default_rsyslog.conf')
            .with_ensure('present')
            .with_content("$IncludeConfig /etc/rsyslog.d/*.conf\n")
        }
      end

      context 'with a single setting and the package rsyslog.conf' do
        let(:hieradata) { 'single_setting' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file('/etc/rsyslog.conf') }

        it {
          is_expected.to contain_file_line('rsyslog rsyslog.conf include rule_dir').with(
            path: '/etc/rsyslog.conf',
            line: '$IncludeConfig /etc/rsyslog.simp.d/*.conf',
            after: '^include\(file="/etc/rsyslog\.d/\*\.conf"',
          )
        }

        it { is_expected.to contain_file('/etc/rsyslog.simp.d').with_ensure('directory').without_purge }
        it { is_expected.to contain_file("#{pre_logging}/10_global.conf").with(content: "global(\n)\n", replace: false) }

        it {
          is_expected.to contain_file_line('rsyslog 10_global net.enableDNS').with(
            path: "#{pre_logging}/10_global.conf",
            line: '  net.enableDNS="off"',
            match: '^\s*net\.enableDNS\s*=',
            after: '^global\(\s*$',
          )
        }

        it 'writes only that setting' do
          expect(rendered).to eq('10_global.conf' => "global(\n  net.enableDNS=\"off\"\n)\n")
        end

        it { is_expected.not_to contain_rsyslog__rule('09_failover_hack/failover_hack.conf') }
        it { is_expected.not_to contain_systemd__dropin_file('simp_limits.conf') }
      end

      context 'with a setting set to absent' do
        let(:hieradata) { 'single_setting_absent' }

        it {
          is_expected.to contain_file_line('rsyslog 10_global net.enableDNS').with(
            ensure: 'absent',
            match: '^\s*net\.enableDNS\s*=',
            match_for_absence: true,
          )
        }
      end

      context 'with settings the package rsyslog.conf already makes' do
        let(:hieradata) { 'package_conf_settings_drop_in' }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_file_line('rsyslog 10_global workDirectory') }
        it { is_expected.not_to contain_file('/var/spool/rsyslog') }
        it { is_expected.not_to contain_rsyslog__config__statement('31_imuxsock') }
        it { is_expected.not_to contain_rsyslog__rule('00_simp_pre_logging/20_omfile.conf') }
      end

      context 'with settings the package rsyslog.conf already makes and replace_rsyslog_conf' do
        let(:hieradata) { 'package_conf_settings_drop_in' }
        let(:facts) do
          super().merge(extra_hiera: 'replace_rsyslog_conf')
        end
        let(:hiera_config) do
          File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
        end

        it { is_expected.to contain_file_line('rsyslog 10_global workDirectory').with_line('  workDirectory="/var/spool/rsyslog"') }
        it { is_expected.to contain_file('/var/spool/rsyslog').with(ensure: 'directory', mode: '0700') }
        it { is_expected.to contain_file_line('rsyslog 31_imuxsock SysSock.Use').with_line('  SysSock.Use="on"') }
        it {
          is_expected.to contain_rsyslog__rule('00_simp_pre_logging/20_omfile.conf')
            .with_content(%(module(load="builtin:omfile" template="RSYSLOG_FileFormat")\n))
        }
      end

      context 'with purge_rule_dir set' do
        let(:hieradata) { 'purge_rule_dir' }
        let(:params) { { rules: { 'some_path/a.conf' => { content: 'x' } } } }

        it { is_expected.to contain_file('/etc/rsyslog.simp.d').with(recurse: true, purge: true, force: true) }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path').with(recurse: true, purge: true, force: true) }
      end

      context 'with legacy globals' do
        let(:hieradata) { 'legacy_globals' }

        it { is_expected.to contain_file("#{pre_logging}/00_legacy.conf").with(content: '', replace: false) }
        it { is_expected.to contain_file_line('rsyslog 00_legacy UMASK').with(line: '$UMASK 0027', match: '^\$UMASK\s') }
        it { is_expected.to contain_file_line('rsyslog 00_legacy AbortOnUncleanConfig').with_ensure('absent') }
        it { is_expected.not_to contain_file_line('rsyslog 00_legacy RepeatedMsgReduction') }
      end

      context 'with localhostname=auto' do
        let(:hieradata) { 'localhostname_auto' }

        it {
          is_expected.to contain_rsyslog__rule('00_simp_pre_logging/11_global_localhostname.conf')
            .with_content(%(global(localHostname="#{os_facts[:networking][:fqdn]}")\n))
        }
      end

      context 'with localhostname=absent' do
        let(:hieradata) { 'localhostname_absent' }

        it { is_expected.to contain_rsyslog__rule('00_simp_pre_logging/11_global_localhostname.conf').with_ensure('absent') }
      end

      context 'with some main queue settings' do
        let(:hieradata) { 'main_queue_partial' }

        it 'writes only those settings, computing auto from the set queue size' do
          expect(rendered).to eq('90_main_queue.conf' => "main_queue(\n  queue.highwatermark=\"900\"\n  queue.size=\"1000\"\n)\n")
        end
      end

      context 'with extra main queue settings' do
        let(:hieradata) { 'extra_main_queue_params' }

        it { is_expected.to contain_file_line('rsyslog 90_main_queue queue.maxdiskspace').with_line('  queue.maxdiskspace="200"') }
        it { is_expected.to contain_file_line('rsyslog 90_main_queue queue.checkpointinterval').with_line('  queue.checkpointinterval="10"') }
      end

      context 'with extra global parameters' do
        let(:hieradata) { 'extra_globals' }

        it {
          is_expected.to contain_rsyslog__rule('00_simp_pre_logging/13_global_janitorInterval.conf')
            .with_content(%(global(janitorInterval="1000")\n))
        }
        it { is_expected.to contain_file_line('rsyslog 00_legacy FailOnChownFailure').with_line('$FailOnChownFailure on') }
      end

      context 'with extra imklog and imfile parameters on the package rsyslog.conf' do
        let(:hieradata) { 'extra_misc_input_module_params' }

        it { is_expected.to contain_file_line('rsyslog 30_imklog RateLimitInterval').with_line('  RateLimitInterval="5"') }
        it { is_expected.to contain_file_line('rsyslog 33_imfile mode').with_line('  mode="inotify"') }
        it { is_expected.not_to contain_rsyslog__config__statement('31_imuxsock') }
        it { is_expected.not_to contain_rsyslog__config__statement('32_imjournal') }
      end

      context 'rsyslog server with TLS enabled' do
        let(:params) { { tls_tcp_server: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('rsyslog::config::tls') }
        it { is_expected.to contain_package('rsyslog-gnutls').with_ensure('installed') }

        it 'writes the listeners and the TLS settings TLS needs' do
          expect(rendered).to eq(
            '12_global_tls.conf' => <<~EOM,
              global(
                defaultNetstreamDriverKeyFile="/etc/pki/simp_apps/rsyslog/x509/private/#{os_facts[:networking][:fqdn]}.pem"
                defaultNetstreamDriverCertFile="/etc/pki/simp_apps/rsyslog/x509/public/#{os_facts[:networking][:fqdn]}.pub"
                defaultNetstreamDriverCAFile="/etc/pki/simp_apps/rsyslog/x509/cacerts/cacerts.pem"
                defaultNetstreamDriver="gtls"
              )
            EOM
            '40_imptcp.conf' => "module(load=\"imptcp\"\n)\ninput(type=\"imptcp\" port=\"514\")\n",
            '41_imtcp.conf' => <<~EOM,
              module(load="imtcp"
                PermittedPeer=["*.#{os_facts[:networking][:domain]}"]
                StreamDriver.AuthMode="x509/name"
                StreamDriver.Mode="1"
              )
              input(type="imtcp" port="6514")
            EOM
          )
        end

        it { is_expected.to contain_file_line('rsyslog 41_imtcp StreamDriver.Mode').with_replace(true) }
        it { is_expected.to contain_file_line('rsyslog 41_imtcp StreamDriver.AuthMode').with_replace(false) }
        it { is_expected.to contain_file_line('rsyslog 41_imtcp PermittedPeer').with_replace(false) }
        it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriverCAFile').with_replace(false) }
      end

      context 'rsyslog server without TLS' do
        let(:params) { { tcp_server: true } }

        it 'writes a plain listener' do
          expect(rendered).to eq('41_imtcp.conf' => "module(load=\"imtcp\"\n)\ninput(type=\"imtcp\" port=\"514\")\n")
        end

        it { is_expected.not_to contain_class('rsyslog::config::tls') }
      end

      context 'rsyslog server with TLS explicitly disabled and TCP enabled' do
        let(:params) { { tls_tcp_server: false, tcp_server: true } }

        it { is_expected.to contain_file("#{pre_logging}/40_imptcp.conf").with_ensure('absent') }
        it { is_expected.to contain_file_line('rsyslog 41_imtcp StreamDriver.Mode').with_ensure('absent') }
        it { is_expected.to contain_file_line('rsyslog 41_imtcp PermittedPeer').with_ensure('absent') }
        it { is_expected.to contain_file_line('rsyslog 41_imtcp input').with_line('input(type="imtcp" port="514")') }
      end

      context 'rsyslog server with every listener disabled' do
        let(:params) { { tls_tcp_server: false, tcp_server: false, udp_server: false } }

        it { is_expected.to contain_file("#{pre_logging}/40_imptcp.conf").with_ensure('absent') }
        it { is_expected.to contain_file("#{pre_logging}/41_imtcp.conf").with_ensure('absent') }
        it { is_expected.to contain_file("#{pre_logging}/42_imudp.conf").with_ensure('absent') }
      end

      context 'rsyslog server with only TCP disabled' do
        let(:params) { { tcp_server: false } }

        it 'leaves a TLS listener from an earlier run alone' do
          is_expected.not_to contain_rsyslog__config__statement('41_imtcp')
        end
      end

      context 'rsyslog server with UDP' do
        let(:params) { { udp_server: true } }

        it 'writes the listener' do
          expect(rendered).to eq('42_imudp.conf' => "module(load=\"imudp\"\n)\ninput(type=\"imudp\" port=\"514\")\n")
        end
      end

      context 'rsyslog class with TLS logging' do
        let(:params) { { enable_tls_logging: true, pki: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.not_to contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
        it { is_expected.to contain_class('rsyslog::config::tls') }
        it { is_expected.to contain_package('rsyslog-gnutls') }
      end

      context 'with TLS settings set to auto, a value and absent' do
        let(:params) { { enable_tls_logging: true } }
        let(:hieradata) { 'tls_globals_auto' }

        it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriver').with(line: '  defaultNetstreamDriver="gtls"', replace: true) }
        it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriverCAFile').with(line: '  defaultNetstreamDriverCAFile="/etc/pki/ca.pem"', replace: true) }
        it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriverKeyFile').with_ensure('absent') }
        it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriverCertFile').with_replace(false) }
      end

      context 'rsyslog class without TLS logging' do
        let(:params) { { enable_tls_logging: false, pki: false } }

        it { is_expected.not_to contain_package('rsyslog-gnutls') }
        it { is_expected.not_to contain_class('pki') }
        it { is_expected.not_to contain_pki__copy('rsyslog') }
        it { is_expected.not_to contain_class('rsyslog::config::tls') }
      end

      context 'rsyslog class with logrotate enabled' do
        let(:params) { { logrotate: true } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('rsyslog::config::logrotate') }
        it { is_expected.to contain_logrotate__rule('syslog') }
      end

      context 'rsyslog class with pki = simp' do
        let(:params) { { pki: 'simp' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
      end

      context 'with rsyslog::config::enable_default_rules=true' do
        let(:hieradata) { 'enable_default_rules' }

        it { is_expected.to contain_rsyslog__rule('99_simp_local/ZZ_default.conf').with_ensure('present') }
      end

      context 'with rsyslog::config::enable_default_rules=false' do
        let(:hieradata) { 'disable_default_rules' }

        it { is_expected.to contain_rsyslog__rule('99_simp_local/ZZ_default.conf').with_ensure('absent') }
      end

      context 'with syslogd_options set' do
        let(:hieradata) { 'syslogd_options' }

        it {
          is_expected.to contain_file_line('rsyslog sysconfig SYSLOGD_OPTIONS').with(
            path: '/etc/sysconfig/rsyslog',
            line: 'SYSLOGD_OPTIONS="-x"',
            match: '^\s*SYSLOGD_OPTIONS=',
          )
        }
      end

      {
        'traditional' => 'RSYSLOG_TraditionalFileFormat',
        'forward' => 'RSYSLOG_ForwardFormat',
        'mytemplate' => 'mytemplate',
      }.each do |template, expected|
        context "with rsyslog::config::default_file_template = #{template}" do
          let(:hieradata) { "#{template}_default_file_template" }

          it {
            is_expected.to contain_rsyslog__rule('00_simp_pre_logging/20_omfile.conf')
              .with_content(%(module(load="builtin:omfile" template="#{expected}")\n))
          }
        end
      end

      context 'with ulimit_max_open_files set to an integer' do
        let(:hieradata) { 'ulimit_max_open_files_integer' }

        it {
          is_expected.to contain_systemd__dropin_file('simp_limits.conf')
            .with_ensure('present')
            .with_unit('rsyslog.service')
            .with_content(%r{LimitNOFILE=65536})
            .that_notifies('Class[rsyslog::service]')
        }
      end

      context "with the deprecated ulimit_max_open_files value 'unlimited'" do
        let(:hieradata) { 'ulimit_max_open_files_unlimited' }

        it { is_expected.to contain_systemd__dropin_file('simp_limits.conf').with_content(%r{LimitNOFILE=infinity}) }
      end

      context 'with ulimit_max_open_files set to absent' do
        let(:hieradata) { 'ulimit_max_open_files_absent' }

        it { is_expected.to contain_systemd__dropin_file('simp_limits.conf').with_ensure('absent') }
      end

      context 'with a rules hash defined' do
        let(:params) do
          {
            rules: {
              'some_path/99_collect_kernel_errors.conf' => {
                content: "if prifilt('kern.err') then /var/log/kernel_errors.log",
              },
              'some_path/98_old.conf' => {
                ensure: 'absent',
                content: '',
              },
            },
          }
        end

        it { is_expected.to contain_rsyslog__rule('some_path/99_collect_kernel_errors.conf').with_content("if prifilt('kern.err') then /var/log/kernel_errors.log") }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path/98_old.conf').with_ensure('absent') }
        it { is_expected.to contain_file_line('rsyslog rsyslog.conf include rule_dir') }
      end
    end
  end
end
