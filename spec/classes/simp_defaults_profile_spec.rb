# frozen_string_literal: true

require 'spec_helper'
require 'yaml'
require_relative '../lib/rendered_config'

# Tests the `simp:defaults` Compliance Engine profile end to end: with
# `compliance_engine::enforcement: [simp:defaults]` set in Hiera, the otherwise
# no-op `include rsyslog` must reproduce the configuration the module managed
# by default before 11.0.0.
#
# The rendered 00_simp_pre_logging files are compared with the complete
# global.conf files that the 10.x module wrote (spec/classes/expected).
#
# The "bare include is a no-op" specs live in init_spec.rb.
describe 'rsyslog' do
  def self.profile_dir
    File.expand_path('../../SIMP/compliance_profiles', __dir__)
  end

  let(:exp_dir) { File.join(__dir__, 'expected') }
  let(:hiera_config) do
    File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
  end

  context 'profile data' do
    let(:checks) { YAML.safe_load_file(File.join(self.class.profile_dir, 'checks.yaml'))['checks'] }
    let(:profile) { YAML.safe_load_file(File.join(self.class.profile_dir, 'profile-simp_defaults.yaml'))['profiles']['simp:defaults'] }

    it 'lists exactly the defined checks (no orphans, none missing)' do
      expect(profile['checks'].keys.sort).to eq(checks.keys.sort)
    end

    it 'only manages rsyslog:: parameters' do
      params = checks.values.map { |c| c['settings']['parameter'] }
      expect(params).to all(start_with('rsyslog::'))
    end

    it 'uses check IDs derived from the parameter name' do
      checks.each do |id, check|
        expect(id).to start_with("simp:defaults.#{check['settings']['parameter'].gsub('::', '.')}")
      end
    end
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:extra_hiera) { nil }
      let(:facts) do
        custom = os_facts.dup
        custom[:rsyslogd] = { 'version' => '8.2102.0' }
        custom[:memory][:system][:total_bytes] = 268_435_456
        custom[:processors][:count] = 4
        custom[:custom_hiera] = hiera_file
        custom[:extra_hiera] = extra_hiera if extra_hiera
        custom
      end

      let(:rendered) { RenderedConfig.statements(RenderedConfig.render(catalogue)) }

      # 11.0.0 binds the UDP listener to rsyslog::udp_listen_address, which
      # 10.x ignored
      def expected_statements(name)
        content = File.read(File.join(exp_dir, name))
        RenderedConfig.statements(content.gsub('input(type="imudp" port=', 'input(type="imudp" address="127.0.0.1" port='))
      end

      context 'when enforcing simp:defaults' do
        let(:hiera_file) { 'simp_defaults_enforced' }

        it { is_expected.to compile.with_all_deps }

        it 'writes the same global configuration as 10.x' do
          expect(rendered).to eq(expected_statements('global_default.txt'))
        end

        it {
          is_expected.to contain_service('rsyslog').with(
            ensure: 'running',
            enable: true,
          )
        }

        it {
          is_expected.to contain_file('/etc/rsyslog.conf').with_content(<<~EOM)
            # This file is managed by Puppet (simp/rsyslog module).
            # Any changes will be overwritten.
            $IncludeConfig /etc/rsyslog.simp.d/*.conf
          EOM
        }

        it { is_expected.not_to contain_file_line('rsyslog rsyslog.conf include rule_dir') }

        it {
          is_expected.to contain_file('/etc/rsyslog.simp.d').with(
            ensure: 'directory',
            mode: '0750',
            recurse: true,
            purge: true,
            force: true,
          )
        }

        it { is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging').with_purge(true) }
        it { is_expected.to contain_file('/etc/rsyslog.d/README_SIMP.conf').with_mode('0640') }
        it { is_expected.to contain_file('/var/spool/rsyslog').with(ensure: 'directory', mode: '0700') }
        it { is_expected.to contain_rsyslog__rule('99_simp_local/ZZ_default.conf').with_ensure('present') }
        it { is_expected.to contain_rsyslog__rule('09_failover_hack/failover_hack.conf') }
        it { is_expected.to contain_rsyslog__rule('15_include_default_rsyslog/include_default_rsyslog.conf').with_ensure('absent') }

        it {
          is_expected.to contain_file_line('rsyslog sysconfig SYSLOGD_OPTIONS').with(
            path: '/etc/sysconfig/rsyslog',
            line: 'SYSLOGD_OPTIONS=""',
          )
        }

        it {
          is_expected.to contain_systemd__dropin_file('simp_limits.conf')
            .with_content(%r{^LimitNOFILE=infinity$})
            .that_notifies('Class[rsyslog::service]')
        }

        it { is_expected.not_to contain_package('rsyslog-gnutls') }
        it { is_expected.not_to contain_exec('rsyslog restart_on_change') }
      end

      {
        'tls_tcp_server' => ['global_tls_tcp_server.txt', { tls_tcp_server: true }],
        'tcp_server' => ['global_tcp_server.txt', { tcp_server: true }],
        'udp_server' => ['global_udp_server.txt', { udp_server: true }],
        'TLS logging' => ['global_tls_logging.txt', { enable_tls_logging: true, pki: true }],
      }.each do |desc, (expected_file, class_params)|
        context "when enforcing simp:defaults with #{desc}" do
          let(:hiera_file) { 'simp_defaults_enforced' }
          let(:params) { class_params }

          it { is_expected.to compile.with_all_deps }

          it 'writes the same global configuration as 10.x' do
            expect(rendered).to eq(expected_statements(expected_file))
          end
        end
      end

      {
        'extra_globals' => ['global_extra_globals.txt', {}],
        'extra_misc_input_module_params' => ['global_extra_misc_input_module_params.txt', {}],
        'extra_main_queue_params' => ['global_extra_main_queue_params.txt', {}],
        'extra_tcp_input_module_params' => ['global_extra_tls_tcp_server_input_module_params.txt', { tls_tcp_server: true }],
        'extra_udp_input_module_params' => ['global_extra_udp_server_input_module_params.txt', { udp_server: true }],
      }.each do |data, (expected_file, class_params)|
        context "when enforcing simp:defaults with #{data}" do
          let(:hiera_file) { 'simp_defaults_enforced' }
          let(:extra_hiera) { data }
          let(:params) { class_params }

          it { is_expected.to compile.with_all_deps }

          it 'writes the same global configuration as 10.x' do
            expect(rendered).to eq(expected_statements(expected_file))
          end
        end
      end

      context 'when enforcing simp:defaults with extra_tcp_input_module_params and tcp_server' do
        let(:hiera_file) { 'simp_defaults_enforced' }
        let(:extra_hiera) { 'extra_tcp_input_module_params' }
        let(:params) { { tcp_server: true } }

        it 'writes the same global configuration as 10.x' do
          expect(rendered).to eq(expected_statements('global_extra_tcp_server_input_module_params.txt'))
        end
      end

      context 'when enforcing simp:defaults with an explicit Hiera override' do
        let(:hiera_file) { 'simp_defaults_with_override' }

        it { is_expected.to compile.with_all_deps }

        it 'lets site Hiera win over the profile' do
          is_expected.to contain_file('/etc/rsyslog.simp.d').without_purge
          is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging').without_purge
        end

        it { is_expected.to contain_service('rsyslog').with_ensure('running') }
      end
    end
  end
end
