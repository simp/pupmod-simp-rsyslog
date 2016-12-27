require 'spec_helper'

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
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        rsyslog_package_name = 'rsyslog'

        if ['RedHat','CentOS'].include?(facts[:operatingsystem])
          if facts[:operatingsystemmajrelease] == '6'
            rsyslog_package_name = 'rsyslog7'
          end
        end

        context 'rsyslog class without any parameters' do
          let(:params) {{ }}
          it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog').with_trusted_nets(['127.0.0.1/32']) }
          it { is_expected.to contain_class('rsyslog').with_service_name('rsyslog') }
          it { is_expected.to contain_class('rsyslog').with_package_name(rsyslog_package_name) }
          it { is_expected.to contain_class('rsyslog').with_tls_package_name("#{rsyslog_package_name}-gnutls") }
          it { is_expected.to contain_package("#{rsyslog_package_name}.x86_64").with_ensure('latest') }
          it { is_expected.to contain_package("#{rsyslog_package_name}.i386").with_ensure('absent') }

          if facts[:operatingsystemmajrelease] == '6'
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
        end

        context 'rsyslog class with logrotate enabled' do
          let(:params) {{
            :logrotate => true
          }}

          it { is_expected.to contain_class('rsyslog::config::logrotate') }
          it { is_expected.to contain_logrotate__rule('syslog')}
        end

        context 'rsyslog class with pki = simp' do
          let(:params) {{
            :pki => 'simp'
          }}

          it { is_expected.to contain_class('pki') }
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
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(/^\$ActionSendStreamDriverAuthMode anon/) }
        end

        context 'rsyslog class with TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :logrotate          => true,
            :enable_tls_logging => true,
            :pki                => true
          }}

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
