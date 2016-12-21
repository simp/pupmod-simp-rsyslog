require 'spec_helper'

describe 'rsyslog::rule::console' do
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
            :rule  => 'test_rule',
            :users => ['one','two']
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_rsyslog__rule('06_simp_console/test_name.conf').with_content(
            /if \(test_rule\) then action\(\s*type="omusrmsg"\n\s*Users="one"\n\s*Users="two"\n\s*\)/
          )
        }
      end
    end
  end
end
