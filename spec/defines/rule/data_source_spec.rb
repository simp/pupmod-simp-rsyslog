require 'spec_helper'

describe 'rsyslog::rule::data_source' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:title) do
          'test_name'
        end

        let(:facts) do
          os_facts
        end

        let(:params) do
          {
            rule: 'test_rule',
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_rsyslog__rule('05_simp_data_sources/test_name.conf').with_content(%r{test_rule}) }

        it 'loads the imfile module that imfile inputs need' do
          is_expected.to contain_file('/etc/rsyslog.simp.d/00_simp_pre_logging/33_imfile.conf')
            .with(content: "module(load=\"imfile\"\n)\n", replace: false)
        end
      end
    end
  end
end
