# frozen_string_literal: true

require 'spec_helper'

# Before 11.0.0, rsyslog::server enabled its SELinux rules whenever SELinux was
# enforcing. The `simp:defaults` profile restores that.
describe 'rsyslog::server' do
  let(:hiera_config) do
    File.expand_path('../fixtures/hieradata/hiera_compliance_engine.yaml', __dir__)
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      [true, false].each do |enforced|
        context "when enforcing simp:defaults with os.selinux.enforced=#{enforced}" do
          let(:facts) do
            custom = os_facts.dup
            custom[:os] = custom[:os].merge(selinux: custom[:os][:selinux].merge(enforced: enforced, current_mode: enforced ? 'enforcing' : 'permissive'))
            custom[:custom_hiera] = 'simp_defaults_enforced'
            custom
          end

          it { is_expected.to compile.with_all_deps }

          if enforced
            it { is_expected.to contain_selboolean('nis_enabled').with_value('on') }
          else
            it { is_expected.not_to contain_class('rsyslog::server::selinux') }
          end
        end
      end
    end
  end
end
