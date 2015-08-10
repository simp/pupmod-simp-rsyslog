require 'spec_helper'

describe 'rsyslog::rule::other' do
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
            :rule  => 'test_rule'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_rsyslog__rule('20_simp_other/test_name.conf').with_content(/test_rule/) }
      end
    end
  end
end
