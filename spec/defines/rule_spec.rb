require 'spec_helper'

describe 'rsyslog::rule' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:title) do
          'some_path/test_name.conf'
        end

        let(:facts) do
          facts
        end

        let(:params) do
          {
            :content => 'random junk'
          }
        end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path').with_ensure('directory') }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path').with_notify('Class[Rsyslog::Service]') }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path.conf').with_content(
          %r(\$IncludeConfig\s+/etc/rsyslog.simp.d/some_path/\*\.conf)
        )}

        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path/test_name.conf').with_content(/random junk/) }
        it { is_expected.to contain_file('/etc/rsyslog.simp.d/some_path/test_name.conf').that_notifies('Class[rsyslog::service]') }

        context "it should fail when provided with an absolute path name" do
          let(:title) do
            '/foo/bar'
          end

          it { is_expected.not_to compile }
        end

        context "it should fail when provided with more than one slash in the name" do
          let(:title) do
            'foo/bar/baz.conf'
          end

          it { is_expected.not_to compile }
        end

        context "it should fail when the name does not end in '.conf'" do
          let(:title) do
            'foo/baz'
          end

          it { is_expected.not_to compile }
        end
      end
    end
  end
end
