require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

describe 'rsyslog' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::params') }
    it { is_expected.to contain_class('rsyslog::config') }

    it do
      is_expected.to contain_class('rsyslog::install').that_comes_before('Class[rsyslog::config]')
      is_expected.to contain_class('rsyslog::service').that_subscribes_to('Class[rsyslog::config]')
    end

    it { is_expected.to contain_service('rsyslog') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:facts) do
          os_facts
        end

        context 'default parameters' do
          rsyslog_package_name = 'rsyslog'

          if ['RedHat','CentOS','OracleLinux'].include?(os_facts[:operatingsystem])
            if os_facts[:operatingsystemmajrelease] == '6'
              rsyslog_package_name = 'rsyslog7'
            end
          end

          let(:params) {{ }}
          it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog').with_trusted_nets(['127.0.0.1/32']) }
          it { is_expected.to contain_class('rsyslog').with_service_name('rsyslog') }
          it { is_expected.to contain_class('rsyslog').with_package_name(rsyslog_package_name) }
          it { is_expected.to contain_class('rsyslog').with_tls_package_name("#{rsyslog_package_name}-gnutls") }
          it { is_expected.to contain_package("#{rsyslog_package_name}.x86_64").with_ensure('latest') }
          it { is_expected.to contain_package("#{rsyslog_package_name}.i386").with_ensure('absent') }

          if os_facts[:operatingsystemmajrelease] == '6'
            it {
              is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
                .without_content(/ModLoad imjournal/)
            }
          else
            it {
              is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
                .with_content(/ModLoad imjournal/)
            }
          end

          if os_facts[:init_systems].include?('systemd')
            it do
              expected = <<EOM
# This file is managed by Puppet.

[unit]

Wants=network.target network-online.target
After=network.target network-online.target
EOM
              is_expected.to contain_systemd__dropin_file('unit.conf')
                .with( {
                  :unit => 'rsyslog.service',
                  :content => expected
                } )

              is_expected.to contain_class('systemd::systemctl::daemon_reload').that_comes_before('Class[rsyslog::service]')
            end

          end

          it 'no file resources should have a literal \n' do
            expect(
              catalogue.resources.select { |resource|
                resource.type == 'File' &&
                  resource[:content] &&
                  resource[:content].include?('\n')
              }
            ).to be_empty
          end
        end

        context 'rsyslog class with logrotate enabled' do
          let(:params) {{
            :logrotate => true
          }}

          it { is_expected.to contain_class('rsyslog::config::logrotate') }
          it { is_expected.to contain_logrotate__rule('syslog')}

          if ['RedHat','CentOS','OracleLinux'].include?(os_facts[:operatingsystem])
            if os_facts[:operatingsystemmajrelease].to_s < '7'
              it { should create_file('/etc/logrotate.d/syslog').with_content(/#{file_content_6}/)}
            else
              it { should create_file('/etc/logrotate.d/syslog').with_content(/#{file_content_7}/)}
            end
          end
        end

        context 'rsyslog class with pki = simp' do
          let(:params) {{
            :pki => 'simp'
          }}

          it { is_expected.to contain_class('pki') }
          it { is_expected.to contain_pki__copy('rsyslog') }
          it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
        end

        context 'rsyslog class with TLS enabled' do
          let(:params) {{
            :tls_tcp_server => true
          }}

          it {
            is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(%r(^\$ActionSendStreamDriverAuthMode x509/name))
          }
        end

        context 'rsyslog class without TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :logrotate   => true,
            :enable_tls_logging => false,
            :pki                => false,
           }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to_not contain_class('pki') }
          it { is_expected.to_not contain_pki__copy('rsyslog') }
          it { is_expected.to_not contain_file('/etc/pki/simp_apps/rsyslog/x509')}
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(/^\$ActionSendStreamDriverAuthMode anon/) }
        end

        context 'rsyslog class with TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :logrotate          => true,
            :enable_tls_logging => true,
            :pki                => true
          }}

          it { is_expected.to_not contain_class('pki') }
          it { is_expected.to contain_pki__copy('rsyslog') }
          it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(%r{^\$ActionSendStreamDriverAuthMode x509/name}) }
        end

        context 'rsyslog server without TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :tcp_server         => true,
            :logrotate          => true,
            :enable_tls_logging => false,
            :pki                => false,
           }}

          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(/514/) }
        end
      end
    end
  end
end
