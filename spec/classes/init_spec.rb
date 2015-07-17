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
    it { is_expected.to contain_package('rsyslog.x86_64').with_ensure('latest') }
    it { is_expected.to contain_package('rsyslog.i386').with_ensure('absent') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'rsyslog class without any parameters' do
          let(:params) {{ }}
          it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog').with_client_nets(['127.0.0.1/32']) }
          it { is_expected.to contain_class('rsyslog').with_service_name('rsyslog') }
          it { is_expected.to contain_class('rsyslog').with_package_name('rsyslog') }
          it { is_expected.to contain_class('rsyslog').with_tls_package_name('rsyslog-gnutls') }
        end

        context 'rsyslog class with logging enabled' do
          let(:parms) {{
            :enable_logging => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::config::logging') }
        end

        context 'rsyslog class with PKI enabled' do
          let(:parms) {{
            :enable_pki => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::config::pki') }
        end
      end
    end
  end
end
