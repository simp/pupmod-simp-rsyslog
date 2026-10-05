require 'spec_helper'

# Per-rule TLS override (use_tls)
describe 'rsyslog::rule::remote' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) { 'test_name' }
      let(:facts) { os_facts.merge(custom_hiera: global_tls ? 'rsyslog_tls' : 'rsyslog__rule__remote') }
      let(:rule_file) { '10_simp_remote/test_name.conf' }

      [true, false].each do |tls|
        context "with rsyslog::enable_tls_logging=#{tls}" do
          let(:global_tls) { tls }

          context 'with use_tls unset' do
            let(:params) { { rule: 'test_rule', dest: ['logs.example.com'] } }

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_class('rsyslog::config::failover_hack') }

            if tls
              it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{StreamDriverMode="1"}) }
              it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{port="6514"}) }
              it { is_expected.to contain_class('rsyslog::config::tls') }
            else
              it { is_expected.to contain_rsyslog__rule(rule_file).without_content(%r{StreamDriver}) }
              it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{port="514"}) }
              it { is_expected.not_to contain_class('rsyslog::config::tls') }
            end
          end

          context 'with use_tls=false' do
            let(:params) do
              {
                rule: 'test_rule',
                dest: ['logs.example.com'],
                failover_log_servers: ['backup.example.com'],
                use_tls: false,
              }
            end

            it { is_expected.to compile.with_all_deps }

            it 'forwards in plain text with an explicit ptcp driver for every action' do
              content = catalogue.resource('Rsyslog::Rule', rule_file)[:content]
              expect(content.scan('StreamDriver="ptcp"').size).to eq(2)
              expect(content).not_to match(%r{StreamDriverMode|StreamDriverAuthMode|StreamDriverPermittedPeers})
              expect(content).not_to include('port="6514"')
            end
          end

          context 'with use_tls=true' do
            let(:params) do
              {
                rule: 'test_rule',
                dest: ['logs.example.com'],
                use_tls: true,
              }
            end

            it { is_expected.to compile.with_all_deps }
            it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{StreamDriverMode="1"}) }
            it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{StreamDriverAuthMode="x509/name"}) }
            it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{StreamDriverPermittedPeers="logs.example.com"}) }
            it { is_expected.to contain_rsyslog__rule(rule_file).with_content(%r{port="6514"}) }
            it { is_expected.to contain_rsyslog__rule(rule_file).without_content(%r{ptcp}) }
            it { is_expected.to contain_class('rsyslog::config::tls') }
            it { is_expected.to contain_package('rsyslog-gnutls') }
            it { is_expected.to contain_file_line('rsyslog 12_global_tls defaultNetstreamDriver').with_line('  defaultNetstreamDriver="gtls"') }
          end

          context 'with use_tls=true and a UDP destination' do
            let(:params) do
              {
                rule: 'test_rule',
                dest: ['logs.example.com'],
                dest_type: 'udp',
                use_tls: true,
              }
            end

            it { is_expected.to contain_rsyslog__rule(rule_file).without_content(%r{StreamDriver}) }
          end

          context 'with ensure=absent' do
            let(:params) { { rule: 'test_rule', dest: ['logs.example.com'], ensure: 'absent' } }

            it { is_expected.to contain_file("/etc/rsyslog.simp.d/#{rule_file}").with_ensure('absent') }
          end
        end
      end
    end
  end
end
