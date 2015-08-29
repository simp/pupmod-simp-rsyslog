require 'spec_helper'

describe 'rsyslog' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::params') }
    it { is_expected.to contain_class('rsyslog::install').that_comes_before('rsyslog::config') }
    it { is_expected.to contain_class('rsyslog::config') }
    it { is_expected.to contain_class('rsyslog::service').that_subscribes_to('rsyslog::config') }

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
          it { is_expected.to contain_class('rsyslog').with_client_nets(['127.0.0.1/32']) }
          it { is_expected.to contain_class('rsyslog').with_service_name('rsyslog') }
          it { is_expected.to contain_class('rsyslog').with_package_name(rsyslog_package_name) }
          it { is_expected.to contain_class('rsyslog').with_tls_package_name("#{rsyslog_package_name}-gnutls") }
          it { is_expected.to contain_package("#{rsyslog_package_name}.x86_64").with_ensure('latest') }
          it { is_expected.to contain_package("#{rsyslog_package_name}.i386").with_ensure('absent') }
        end


        context 'rsyslog class with logrotate enabled' do
          let(:params) {{
            :enable_logrotate => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::config::logrotate') }
          it { is_expected.to contain_logrotate__add('syslog')}
        end

        context 'rsyslog class with PKI enabled' do
          let(:params) {{
            :enable_pki => true
         }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(%r(^\$ActionSendStreamDriverAuthMode x509/name)) }
        end


        context 'rsyslog class without TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :enable_logrotate   => true,
            :enable_tls_logging => false,
            :enable_pki         => false,
           }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(/^\$ActionSendStreamDriverAuthMode anon/) }
        end


        context 'rsyslog class with TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :enable_logrotate   => true,
            :enable_tls_logging => true,
            :enable_pki         => true,
           }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(%r{^\$ActionSendStreamDriverAuthMode x509/name}) }
        end

        context 'rsyslog server without TLS' do
          # rsyslog needs to disable pki/tls
          let(:params) {{
            :tcp_server         => true,
            :enable_logrotate   => true,
            :enable_tls_logging => false,
            :enable_pki         => false,
           }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf').with_content(/514/) }
        end

      end
    end
  end
end
