require 'spec_helper'


describe 'rsyslog' do
  shared_examples_for 'a structured module' do
    it { is_expected.to compile.with_all_deps }
    it { is_expected.to create_class('rsyslog') }
    it { is_expected.to contain_class('rsyslog::config') }
    it { is_expected.to contain_class('rsyslog::install').that_comes_before('Class[rsyslog::config]') }
    it { is_expected.to contain_class('rsyslog::service').that_subscribes_to('Class[rsyslog::config]') }
  end

  shared_examples_for 'rsyslog base install' do
    it { is_expected.to contain_package('rsyslog.x86_64').with_ensure('installed') }
    it { is_expected.to contain_package('rsyslog.i386').with_ensure('absent') }
  end

  shared_examples_for 'rsyslog base configuration' do
    it { is_expected.to contain_file('/etc/rsyslog.simp.d').with(
      :ensure => 'directory',
      :mode   => '0750'
    ) }

    it { is_expected.to contain_file('/etc/rsyslog.d').with(
      :ensure => 'directory',
      :mode   => '0755'
    ) }

    it {
      expected = <<~EOM
        # In Puppet hieradata, set 'rsyslog::config::include_rsyslog_d' to true
        # and place ".conf" files that rsyslog should process independently of
        # SIMP into this directory.
      EOM
      is_expected.to contain_file('/etc/rsyslog.d/README_SIMP.conf').with_content(expected)
    }

    it { is_expected.to contain_file('/var/spool/rsyslog').with(
      :ensure => 'directory',
      :mode   => '0700'
    ) }

    it {
      expected = <<~EOM
        # This file is managed by Puppet (simp/rsyslog module).
        # Any changes will be overwritten.
        $IncludeConfig /etc/rsyslog.simp.d/*.conf
      EOM
      is_expected.to contain_file('/etc/rsyslog.conf').with_content(expected)
    }


    it { is_expected.to contain_file('/etc/sysconfig/rsyslog').with_content( <<~EOM
        # This file is managed by Puppet (simp/rsyslog module).
        # Any changes will be overwritten.
        SYSLOGD_OPTIONS=""
      EOM
    ) }

    it { is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf') }
    it { is_expected.to contain_rsyslog__rule('09_failover_hack/failover_hack.conf') }
    it { is_expected.to contain_init_ulimit('mod_open_files_rsyslog').with(
      :target => 'rsyslog',
      :item   => 'max_open_files',
      :value  => 'unlimited'
    ) }
  end

  shared_examples_for 'rsyslog base service' do
    it { is_expected.to contain_service('rsyslog').with(
      :ensure     => 'running',
      :enable     => true,
      :hasrestart => true,
      :hasstatus  => true
    ) }
  end

  shared_examples_for 'a rsyslog manager' do
    include_examples 'a structured module'
    include_examples 'rsyslog base install'
    include_examples 'rsyslog base configuration'
    include_examples 'rsyslog base service'
  end

  let(:exp_dir) { File.join(__dir__, 'expected') }

  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:facts) do
        if os_facts[:operatingsystemmajrelease] < '8'
          version = '8.24.0'   # CentOS 7: 7.4 and later
        else
          version = '8.1911.0' # CentOS 8: 8.2 and later
        end

        custom = {
          :rsyslogd       => { 'version' => version },
          :memorysize_mb  => 256,
          :processorcount => 4
         }
        os_facts.merge(custom)
      end

      let(:global_conf_file) { '/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf' }

      context 'default parameters' do
        let(:params) {{ }}
        let(:global_expected) { File.read("#{exp_dir}/global_default.txt") }

        it_behaves_like 'a rsyslog manager'
        it { is_expected.to contain_class('rsyslog').with_trusted_nets(['127.0.0.1/32']) }
        it { is_expected.to contain_class('rsyslog').with_tls_package_name('rsyslog-gnutls') }
        it { is_expected.to contain_rsyslog__rule('99_simp_local/ZZ_default.conf') }
        it { is_expected.to contain_rsyslog__rule('00_simp_pre_logging/global.conf') }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }


        if os_facts[:operatingsystemmajrelease] < '8'
          it do
            expected = <<~EOM
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
        let(:params) {{ :logrotate => true }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('rsyslog::config::logrotate') }
        it { is_expected.to contain_logrotate__rule('syslog')}

        it { should create_file('/etc/logrotate.simp.d/syslog').with_content(
          %r{/usr/bin/systemctl restart rsyslog > /dev/null 2>&1 || true"})
        }
      end

      context 'rsyslog class with pki = simp' do
        let(:params) {{ :pki => 'simp' }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
        it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
      end

      context 'rsyslog class without TLS logging' do
        # enable_tls_logging and pki are actually set to false by default,
        # but checks separated out here for easy comparison with
        # 'rsyslog class with TLS logging'
        let(:params) {{
          :enable_tls_logging => false,
          :pki                => false,
         }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_package('rsyslog-gnutls') }
        it { is_expected.to_not contain_class('pki') }
        it { is_expected.to_not contain_pki__copy('rsyslog') }
        it { is_expected.to_not contain_file('/etc/pki/simp_apps/rsyslog/x509')}
        it { is_expected.to_not contain_file(global_conf_file).with_content(/defaultNetStreamDriverCertFile/) }
        it { is_expected.to_not contain_file(global_conf_file).with_content(/defaultNetStreamDriver/) }
        it { is_expected.to_not contain_file(global_conf_file).with_content(/defaultNetStreamDriverCAFile/) }
        it { is_expected.to_not contain_file(global_conf_file).with_content(/defaultNetStreamDriverKeyFile/) }
      end

      context 'rsyslog class with TLS logging' do
        let(:params) {{
          :enable_tls_logging => true,
          :pki                => true
        }}

        let(:global_expected) { File.read("#{exp_dir}/global_tls_logging.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_class('pki') }
        it { is_expected.to contain_pki__copy('rsyslog') }
        it { is_expected.to contain_file('/etc/pki/simp_apps/rsyslog/x509')}
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'rsyslog server with TLS enabled' do
        let(:params) {{ :tls_tcp_server => true }}
        let(:global_expected) { File.read("#{exp_dir}/global_tls_tcp_server.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end


      context 'rsyslog server without TLS' do
        let(:params) {{ :tcp_server => true }}
        let(:global_expected) { File.read("#{exp_dir}/global_tcp_server.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'rsyslog server with UDP' do
        let(:params) {{ :udp_server => true }}
        let(:global_expected) { File.read("#{exp_dir}/global_udp_server.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'with read_journald=false' do
        let(:params) {{ :read_journald => false }}

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to_not contain_file(global_conf_file)
          .with_content(/module\(load="imjournal"/)
        }
      end

      context 'including the rsyslog.d directory' do
        let(:hieradata) { 'include_rsyslog_d' }
        it {
          is_expected.to contain_rsyslog__rule('15_include_default_rsyslog/include_default_rsyslog.conf')
            .with_content("$IncludeConfig /etc/rsyslog.d/*.conf\n") }
      end

      context 'with rsyslog::config::enable_default_rules=false' do
        let(:hieradata) { 'disable_default_rules' }
        it { is_expected.to_not contain_rsyslog__rule('99_simp_local/ZZ_default.conf') }
      end

      context 'with rsyslog::config::default_file_template = traditional' do
        let(:hieradata) { 'traditional_default_file_template' }
        it { is_expected.to contain_file(global_conf_file).with_content(
          %r{module\(load="builtin:omfile" template="RSYSLOG_TraditionalFileFormat"})
        }
      end

      context 'with rsyslog::config::default_file_template = forward' do
        let(:hieradata) { 'forward_default_file_template' }
        it { is_expected.to contain_file(global_conf_file).with_content(
          %r{module\(load="builtin:omfile" template="RSYSLOG_ForwardFormat"})
        }
      end

      context 'with rsyslog::config::default_file_template = mytemplate' do
        let(:hieradata) { 'mytemplate_default_file_template' }
        it { is_expected.to contain_file(global_conf_file).with_content(
          %r{module\(load="builtin:omfile" template="mytemplate"})
        }
      end

      context 'with extra global and legacy global parameters set' do
        let(:hieradata) { 'extra_globals' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_globals.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'with optional imklog, imuxsock, imjournal, and imfile module parameters set' do
        let(:hieradata) { 'extra_misc_input_module_params' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_misc_input_module_params.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'rsyslog server with TLS and optional config parameters set' do
        let(:params) {{ :tls_tcp_server => true }}
        let(:hieradata) { 'extra_tcp_input_module_params' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_tls_tcp_server_input_module_params.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'rsyslog server simple TCP and optional config parameters set' do
        let(:params) {{ :tcp_server => true }}
        let(:hieradata) { 'extra_tcp_input_module_params' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_tcp_server_input_module_params.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'rsyslog server with UDP and optional config parameters set' do
        let(:params) {{ :udp_server => true }}
        let(:hieradata) { 'extra_udp_input_module_params' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_udp_server_input_module_params.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

      context 'with optional main_queue config parameters set' do
        let(:hieradata) { 'extra_main_queue_params' }
        let(:global_expected) { File.read("#{exp_dir}/global_extra_main_queue_params.txt") }

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_file(global_conf_file).with_content(global_expected) }
      end

    end # end `context "on #{os}"...`
  end  # end `on_supported_os.each...`
end
