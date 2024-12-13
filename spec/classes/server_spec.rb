require 'spec_helper'

describe 'rsyslog::server' do
  def mock_selinux_false_facts(os_facts)
    os_facts[:os][:selinux][:config_mode] = 'disabled'
    os_facts[:os][:selinux][:current_mode] = 'disabled'
    os_facts[:os][:selinux][:enabled] = false
    os_facts[:os][:selinux][:enforced] = false
    os_facts
  end

  def mock_selinux_enforcing_facts(os_facts)
    os_facts[:os][:selinux][:config_mode] = 'enforcing'
    os_facts[:os][:selinux][:config_policy] = 'targeted'
    os_facts[:os][:selinux][:current_mode] = 'enforcing'
    os_facts[:os][:selinux][:enabled] = true
    os_facts[:os][:selinux][:enforced] = true
    os_facts
  end
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to contain_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::server') }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        facts = os_facts.dup
        facts = mock_selinux_false_facts(facts)
        facts
      end

      context 'rsyslog::server class with default parameters and SELinux disabled' do
        let(:params) { {} }

        it_behaves_like 'a structured module'
        it { is_expected.not_to contain_class('rsyslog::server::firewall') }
        it { is_expected.not_to contain_class('rsyslog::server::tcpwrappers') }
        it { is_expected.not_to contain_class('rsyslog::server::selinux') }
      end

      context 'rsyslog::server class with firewall enabled' do
        let(:params) { { enable_firewall: true } }

        it { is_expected.to contain_class('rsyslog::server::firewall') }

        context 'and tls_tcp_server enabled' do
          let(:pre_condition) { 'class{ "rsyslog" : tls_tcp_server => true }' }

          it {
            is_expected.to create_iptables__listen__tcp_stateful('syslog_tls_tcp')
              .with_dports(6514)
          }

          context 'and tls_tcp_listen_port = 9999' do
            let(:pre_condition) do
              'class{ "rsyslog":
                 tls_tcp_server => true,
                 tls_tcp_listen_port => 9999,
              }'
            end

            it {
              is_expected.to create_iptables__listen__tcp_stateful('syslog_tls_tcp')
                .with_dports(9999)
            }
          end
        end

        context 'and tcp_server enabled' do
          let(:pre_condition) { 'class{ "rsyslog" : tcp_server => true }' }

          it {
            is_expected.to create_iptables__listen__tcp_stateful('syslog_tcp')
              .with_dports(514)
          }

          context 'and tcp_listen_port = 9999' do
            let(:pre_condition) do
              'class{ "rsyslog":
                 tcp_server => true,
                 tcp_listen_port => 9999,
              }'
            end
            let(:params) { { enable_firewall: true } }

            it {
              is_expected.to create_iptables__listen__tcp_stateful('syslog_tcp')
                .with_dports(9999)
            }
          end
        end

        context 'and udp_server enabled' do
          let(:pre_condition) { 'class{ "rsyslog" : udp_server => true }' }

          it {
            is_expected.to create_iptables__listen__udp('syslog_udp')
              .with_dports(514)
          }

          context 'and udp_listen_port = 9999' do
            let(:pre_condition) do
              'class{ "rsyslog":
                 udp_server => true,
                 udp_listen_port => 9999,
              }'
            end

            it {
              is_expected.to create_iptables__listen__udp('syslog_udp')
                .with_dports(9999)
            }
          end
        end
      end

      context 'rsyslog::server class with SELinux enabled' do
        let(:facts) do
          facts = os_facts.dup
          facts = mock_selinux_enforcing_facts(facts)
          facts
        end

        it { is_expected.to compile.with_all_deps }
        it_behaves_like 'a structured module'
        it { is_expected.to contain_class('rsyslog::server::selinux') }
        it do
          is_expected.to create_selboolean('nis_enabled').with(
            persistent: true,
            value: 'on',
          )
        end
      end

      context 'with fact os.selinux.enforced unset' do
        let(:facts) do
          facts = os_facts.dup
          facts[:os][:selinux][:enforced] = nil
          facts
        end

        it_behaves_like 'a structured module'
        it { is_expected.to contain_class('rsyslog::server') }
        it { is_expected.not_to contain_class('rsyslog::server::selinux') }
      end

      context 'rsyslog::server class with TCPWrappers enabled' do
        let(:params) { { enable_tcpwrappers: true } }

        it_behaves_like 'a structured module'
        it { is_expected.to contain_class('rsyslog::server::tcpwrappers') }
      end
    end
  end
end
