require 'spec_helper'

describe 'rsyslog::rule::console' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) do
        'test_name'
      end

      let(:facts) do
        os_facts
      end

      context 'single line rule without whitespace prefix' do
        let(:params) do
          {
            rule: 'test_rule',
            users: ['one', 'two'],
          }
        end

        it { is_expected.to compile.with_all_deps }
        it {
          is_expected.to contain_rsyslog__rule('06_simp_console/test_name.conf').with_content(
            %r{if \(test_rule\) then action\(\s*type="omusrmsg"\n\s*Users="one"\n\s*Users="two"\n\s*\)},
          )
        }
      end

      context 'multi-line rule with whitespace prefixes' do
        let(:params) do
          {
            rule: " line_one\n\tline_two",
            users: ['one', 'two'],
          }
        end

        it {
          is_expected.to contain_rsyslog__rule('06_simp_console/test_name.conf').with_content(
            %r{if \(line_one\nline_two\) then action\(\s*type="omusrmsg"\n\s*Users="one"\n\s*Users="two"\n\s*\)},
          )
        }
        it { is_expected.to compile.with_all_deps }
      end
    end
  end
end
