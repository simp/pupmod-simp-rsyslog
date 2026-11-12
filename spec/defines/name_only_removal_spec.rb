require 'spec_helper'

# Removing a rule or template needs only its name. The behavior does not
# depend on the OS, so one is enough.
{
  'rsyslog::rule'              => ['some_path/test_name.conf', 'some_path/test_name.conf', %r{\$content is required}],
  'rsyslog::rule::console'     => ['test_name', '06_simp_console/test_name.conf', %r{\$rule and \$users are required}],
  'rsyslog::rule::data_source' => ['test_name', '05_simp_data_sources/test_name.conf', %r{\$rule is required}],
  'rsyslog::rule::drop'        => ['test_name', '07_simp_drop_rules/test_name.conf', %r{\$rule is required}],
  'rsyslog::rule::other'       => ['test_name', '20_simp_other/test_name.conf', %r{\$rule is required}],
  'rsyslog::rule::local'       => ['test_name', '99_simp_local/test_name.conf', %r{You must specify "\$rule"}],
  'rsyslog::rule::remote'      => ['test_name', '10_simp_remote/test_name.conf', %r{You must specify "\$rule"}],
  'rsyslog::template::list'    => ['test_name', '05_simp_templates/test_name.conf', %r{\$content is required}],
  'rsyslog::template::plugin'  => ['test_name', '05_simp_templates/test_name.conf', %r{\$plugin is required}],
  'rsyslog::template::string'  => ['test_name', '05_simp_templates/test_name.conf', %r{\$string is required}],
  'rsyslog::template::subtree' => ['test_name', '05_simp_templates/test_name.conf', %r{\$subtree is required}],
}.each do |type, (rule_title, path, error)|
  describe type do
    context "on #{on_supported_os.keys.first}" do
      let(:title) { rule_title }
      let(:facts) { on_supported_os.values.first }

      context 'with ensure=absent and no other parameters' do
        let(:params) { { ensure: 'absent' } }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file("/etc/rsyslog.simp.d/#{path}").with_ensure('absent') }
        it { is_expected.not_to contain_class('rsyslog::config::rule_tree') }
      end

      context 'with ensure=present and no other parameters' do
        it { is_expected.to compile.and_raise_error(error) }
      end
    end
  end
end
