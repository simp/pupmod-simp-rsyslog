require 'spec_helper'

describe 'rsyslog::config' do
  context 'supported operating systems' do
    on_supported_os.each do |os, facts|
      context "on #{os}" do
        let(:facts) do
          facts
        end
        let(:params) do
          { 'action_send_stream_driver_permitted_peers' => ['10.0.2.15'] }
        end

        context 'rsyslog::config class with default config' do
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to create_class('rsyslog::config') }
          it { is_expected.to contain_class('rsyslog') }


          if facts[:operatingsystemmajrelease] == '6'
            it {
              params.merge!({ 'read_journald' => false })
              is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
                .without_content(/ModLoad imjournal/)
            }
          else
            it {
              params.merge!({ 'read_journald' => true })
              is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
                .with_content(/ModLoad imjournal/)
            }
          end

        end
      end
    end
  end
end