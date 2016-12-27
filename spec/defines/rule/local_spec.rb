require 'spec_helper'

describe 'rsyslog::rule::local' do
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
            :rule      => 'test_rule',
            :dyna_file => 'test_file'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_rsyslog__rule('99_simp_local/test_name.conf').with_content(
          /if \(#{params[:rule]}\) then\s+{\n\s*action\(\n\s*type="omfile"\n\s*dynaFile="#{params[:dyna_file]}"/
        ) }
      end
    end
  end
end
