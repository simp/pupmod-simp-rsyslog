require 'spec_helper'

describe 'rsyslog::rule::remote' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:title) do
          'test_name'
        end

        let(:facts) do
          facts
        end

        let(:params) do
          {
            :rule => 'test_rule',
            :dest => ['1.2.3.4','5.6.7.8']
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(
          /ruleset\(\n\s*name="ruleset_#{title}"/
        ) }
        it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(
          /if \(#{params[:rule]}\) then call ruleset_#{title}/
        ) }
      end
    end
  end
end
