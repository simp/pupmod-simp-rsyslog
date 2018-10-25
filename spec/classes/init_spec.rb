require 'spec_helper'

file_content_7 = "/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"
file_content_6 = "/sbin/service rsyslog restart > /dev/null 2>&1 || true"

reg_exp_el7 = <<EOM
main_queue\(
  queue.type=.*
  queue.filename=.*
  queue.maxfilesize=.*
  queue.size=.*
  queue.highwatermark=.*
  queue.lowwatermark=.*
  queue.discardmark=.*
  queue.workerthreadminimummessages=.*
  queue.workerthreads=.*
  queue.timeoutenqueue=.*
  queue.dequeueslowdown=.*
  queue.saveonshutdown=.*
  queue.maxdiskspace=.*
\)
EOM

describe 'rsyslog' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::params') }
    it { is_expected.to contain_class('rsyslog::config') }
    it {
      expected = <<EOM
# In Puppet hieradata, set 'rsyslog::config::include_rsyslog_d' to true
# and place ".conf" files that rsyslog should process independently of
# SIMP into this directory.
EOM
      is_expected.to contain_file('/etc/rsyslog.d/README_SIMP.conf').with_content(expected)
    }

    it do
      is_expected.to contain_class('rsyslog::install').that_comes_before('Class[rsyslog::config]')
      is_expected.to contain_class('rsyslog::service').that_subscribes_to('Class[rsyslog::config]')
    end

    it { is_expected.to contain_service('rsyslog') }
  end

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        rsyslog_facts = {
          :rsyslogd => {
            'version' => '8.0.0'
          }
        }

        if os_facts[:operatingsystemmajrelease] == '6'
          rsyslog_facts[:rsyslogd]['version'] = '5.2.1'
        end

        os_facts.merge(rsyslog_facts)
      end

      let(:global_conf_file) { '/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf' }

      context 'default parameters' do
        rsyslog_package_name = 'rsyslog'

        if os_facts[:operatingsystemmajrelease] == '6'
          rsyslog_package_name = 'rsyslog7'
        end

        let(:params) {{ }}
        it_behaves_like 'a structured module'
        it { is_expected.to contain_class('rsyslog').with_trusted_nets(['127.0.0.1/32']) }
        it { is_expected.to contain_class('rsyslog').with_service_name('rsyslog') }
        it { is_expected.to contain_class('rsyslog').with_package_name(rsyslog_package_name) }
        it { is_expected.to contain_class('rsyslog').with_tls_package_name("#{rsyslog_package_name}-gnutls") }
        it { is_expected.to contain_package("#{rsyslog_package_name}.x86_64").with_ensure('installed') }
        it { is_expected.to contain_package("#{rsyslog_package_name}.i386").with_ensure('absent') }

        if os_facts[:operatingsystemmajrelease] == '6'
          it {
            is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
              .without_content(/ModLoad imjournal/)
          }
          it {
            is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
              .with_content(/[$]?MainMsgQueueType LinkedList\n[$]?MainMsgQueueFilename main_msg_queue\n[$]?MainMsgQueueMaxFileSize [\d]*M\n[$]?MainMsgQueueSize [\d]*\n[$]?MainMsgQueueHighWatermark [\d]*\n[$]?MainMsgQueueLowWatermark [\d]*\n[$]?MainMsgQueueDiscardMark [\d]*\n[$]?MainMsgQueueWorkerThreadMinimumMessages [\d]*\n[$]?MainMsgQueueWorkerThreads [\d]*\n[$]?MainMsgQueueTimeoutEnqueue 100\n[$]?MainMsgQueueDequeueSlowdown 0\n[$]?MainMsgQueueSaveOnShutdown on\n[$]?MainMsgQueueMaxDiskSpace [\d]*M/)
          }
        else
          it {
            is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
              .with_content(/ModLoad imjournal/)
          }
          it {
            is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
              .with_content(/queue.type=\"LinkedList\"\n  queue.filename=\"main_msg_queue\"\n  queue.maxfilesize=\"[\d]*M\"\n  queue.size=\"[\d]*\"\n  queue.highwatermark=\"[\d]*\"\n  queue.lowwatermark=\"[\d]*\"\n  queue.discardmark=\"[\d]*\"\n  queue.workerthreadminimummessages=\"[\d]*\"\n  queue.workerthreads=\"[\d]*\"\n  queue.timeoutenqueue=\"100\"\n  queue.dequeueslowdown=\"0\"\n  queue.saveonshutdown=\"on\"\n  queue.maxdiskspace=\"[\d]*M\"/)
          }
        end

        if os_facts[:init_systems].include?('systemd')
          it do
            expected = <<EOM
# This file is managed by Puppet.

[Unit]

Wants=network.target network-online.target
After=network.target network-online.target
EOM
            is_expected.to contain_systemd__dropin_file('unit.conf')
              .with( {
                :unit => 'rsyslog.service',
                :content => expected
              } )

            is_expected.to contain_class('systemd::systemctl::daemon_reload')
              .that_comes_before('Class[rsyslog::service]')
          end

        end

        it 'no file resources should have a literal \n' do
          expect(
            catalogue.resources.select { |resource|
              resource.type == 'File' &&
                resource[:content] &&
                resource[:content].include?('\n')
            }
          ).to be_empty
        end
      end

      context 'rsyslog class with logrotate enabled' do
        let(:params) {{
          :logrotate => true
        }}

        it { is_expected.to contain_class('rsyslog::config::logrotate') }
        it { is_expected.to contain_logrotate__rule('syslog')}

        if os_facts[:operatingsystemmajrelease].to_s < '7'
          it { should create_file('/etc/logrotate.simp.d/syslog').with_content(/#{file_content_6}/)}
        else
          it { should create_file('/etc/logrotate.simp.d/syslog').with_content(/#{file_content_7}/)}
        end
      end

      context 'rsyslog class with pki = simp' do
        let(:params) {{
          :pki => 'simp'
        }}

        it { is_expected.to contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
        it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
      end

      context 'rsyslog class without TLS' do
        # rsyslog needs to disable pki/tls
        let(:params) {{
          :logrotate   => true,
          :enable_tls_logging => false,
          :pki                => false,
         }}


        it { is_expected.to_not contain_class('pki') }
        it { is_expected.to_not contain_pki__copy('rsyslog') }
        it { is_expected.to_not contain_file('/etc/pki/simp_apps/rsyslog/x509')}
        it { is_expected.to_not contain_file(global_conf_file).with_content(/^\$DefaultNetStreamDriver/) }
        it { is_expected.to_not contain_file(global_conf_file).with_content(/^\$ActionSendStreamDriverMode/) }
      end

      context 'rsyslog class with TLS' do
        # rsyslog needs to disable pki/tls
        let(:params) {{
          :logrotate          => true,
          :enable_tls_logging => true,
          :pki                => true
        }}

        it { is_expected.to_not contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
        it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverCertFile /etc/pki/simp_apps/rsyslog/x509/public/foo.example.com.pub})
        }

        it { is_expected.to contain_file(global_conf_file).with_content(%r{^\$DefaultNetstreamDriver gtls}) }
        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverCAFile /etc/pki/simp_apps/rsyslog/x509/cacerts/cacerts.pem})
        }

        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverKeyFile /etc/pki/simp_apps/rsyslog/x509/private/foo.example.com.pem})
        }

        if os_facts[:operatingsystemmajrelease] == '6'
          it { is_expected.to contain_file(global_conf_file).with_content(%r{^\$ActionSendStreamDriverMode 1}) }
        end
      end

      context 'rsyslog server with TLS enabled' do
        let(:params) {{
          :tls_tcp_server => true
        }}

        it { is_expected.to contain_file(global_conf_file).with_content(%r{^module\(load="imtcp"}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{StreamDriver.Mode="1"}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{StreamDriver.AuthMode="x509/name"}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{PermittedPeer=\["\*\.example.com"\]}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{MaxSessions="200"}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{input\(type="imtcp" port="6514"\)}) }

        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverCertFile /etc/pki/simp_apps/rsyslog/x509/public/foo.example.com.pub})
        }

        it { is_expected.to contain_file(global_conf_file).with_content(%r{^\$DefaultNetstreamDriver gtls}) }
        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverCAFile /etc/pki/simp_apps/rsyslog/x509/cacerts/cacerts.pem})
        }

        it { is_expected.to contain_file(global_conf_file)
          .with_content(%r{^\$DefaultNetstreamDriverKeyFile /etc/pki/simp_apps/rsyslog/x509/private/foo.example.com.pem})
        }

      end


      context 'rsyslog server without TLS' do
        # rsyslog needs to disable pki/tls
        let(:params) {{
          :tcp_server         => true,
          :logrotate          => true,
          :enable_tls_logging => false,
          :pki                => false,
         }}

        it { is_expected.to contain_file(global_conf_file).with_content(%r{^module\(load="imtcp"}) }
        it { is_expected.to contain_file(global_conf_file).with_content(%r{input\(type="imtcp" port="514"\)}) }
        it { is_expected.to_not contain_file(global_conf_file).with_content(/^\$DefaultNetStreamDriver/) }
      end
    end
    context "with later versions of rsyslog on #{os}" do
      let(:facts) do
        rsyslog_facts = {
          :rsyslogd => {
            'version' => '8.6.0'
          }
        }
        if os_facts[:operatingsystemmajrelease] == '6'
           rsyslog_facts[:rsyslogd]['version'] = '7.4.10'
        end
        os_facts.merge(rsyslog_facts)
      end
      let(:hieradata) { 'rsyslog_config_settings' }

      if os_facts[:operatingsystemmajrelease] == '6'
        it {
          is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
            .without_content(/net.permitACLWarning=\"off\"\n  net.enableDNS="off"\n/)
        }
        it {
          is_expected.to contain_file('/etc/sysconfig/rsyslog').with_content(/SYSLOGD_OPTIONS=\" -l my.host.com -s foo.bar -x\"$/)
        }
      else
        it {
          is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf')
            .with_content(/net.permitACLWarning=\"off\"\n  net.enableDNS="off"\n/)
        }
        it {
          is_expected.to contain_file('/etc/sysconfig/rsyslog').with_content(/SYSLOGD_OPTIONS=\"\"$/)
        }
      end
    end
  end
end
