require 'spec_helper'

describe 'rsyslog::server' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rsyslog::server') }
    it { is_expected.to contain_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::server') }
  end

  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end

        context 'rsyslog server class without any parameters' do
          let(:params) {{ }}
          it_behaves_like 'a structured module'
        end

        context 'rsyslog class with firewall enabled' do
          let(:parms) {{
            :enable_firewall => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::server::firewall') }
        end

        context 'rsyslog class with SELinux enabled' do
          let(:parms) {{
            :enable_selinux => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::server::selinux') }
        end

        context 'rsyslog class with TCPWrappers enabled' do
          let(:parms) {{
            :enable_tcpwrappers => true
          }}
          ###it_behaves_like 'a structured module'
          it { is_expected.to contain_class('rsyslog::server::tcpwrappers') }
        end
      end
    end
  end
end
