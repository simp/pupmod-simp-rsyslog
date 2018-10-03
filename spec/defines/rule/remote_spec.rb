require 'spec_helper'

describe 'rsyslog::rule::remote' do
  on_supported_os.each do |os, os_facts|
    context "on #{os}" do
      let(:title) do
        'test_name'
      end

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

      context 'without TLS' do

        context 'with rule and default parameters' do
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['1.2.3.4','5.6.7.8:5678']
            }
          end
          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_defaults.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
        end

        context 'with rule and all optional non-TLS params specified' do
          let(:params) do
            {
              :rule => 'test_rule',
              :stop_processing                      => true,
              :template                             => 'my_template',
              :dest                                 => ['1.2.3.4'],
              :dest_type                            => 'relp',
              :failover_log_servers                 => ['5.6.7.8:5678', '9.10.11.12'],
              :tcp_framing                          => 'octet-counted',
              :zip_level                            => 1,
              :max_error_messages                   => 6,
              :compression_mode                     => 'single',
              :compression_stream_flush_on_tx_end   => false,
              :rebind_interval                      => 1,
              :action_resume_interval               => 40,
              :action_resume_retry_count            => 1,
              :resend_last_msg_on_reconnect         => false,
              :udp_send_to_all                      => true,
              :queue_filename                       => 'my_queue',
              :queue_spool_directory                => '/var/my_rsyslog',
              :queue_size                           => 1000,
              :queue_dequeue_batch_size             => 100,
              :queue_max_disk_space                 => 100000,
              :queue_high_watermark                 => 900,
              :queue_low_watermark                  => 200,
              :queue_full_delay_mark                => 940,
              :queue_light_delay_mark               => 300,
              :queue_discard_mark                   => 975,
              :queue_discard_severity               => 7,
              :queue_checkpoint_interval            => 2,
              :queue_sync_queue_files               => true,
              :queue_type                           => 'LinkedList',
              :queue_worker_threads                 => 2,
              :queue_timeout_shutdown               => 1,
              :queue_timeout_action_completion      => 100,
              :queue_timeout_enqueue                => 200,
              :queue_timeout_worker_thread_shutdown => 6000,
              :queue_worker_thread_minimum_messages => 10,
              :queue_max_file_size                  => '2m',
              :queue_save_on_shutdown               => true,
              :queue_dequeue_slowdown               => 0,
              :queue_dequeue_time_begin             => 1,
              :queue_dequeue_time_end               => 2
            }
          end
          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_with_settings.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
        end
      end

      context 'with TLS' do
        let(:hieradata) { "rsyslog_tls" }
        context 'with rule and all hostnames dests' do

          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['logserver.my.domain', 'logserver2.other.place:4444']
            }
          end
          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_tls_with_peers_undef_hostname_for_logserver.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
        end

        context 'with rule and all hostnames remotes' do
          let(:params) do
            {
              :rule                  => 'test_rule',
              :dest                  => ['logserver.my.domain', 'logserver2.other.place:4444'],
              :failover_log_servers  => ['failover.my.domain', 'failover.other.place:4444']
            }
          end
          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_tls_with_peers_undef_hostname_for_remotes.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
        end

        context 'with rule optional stream_driver params' do
          let(:params) do
            {
              :rule                          => 'test_rule',
              :dest                          => ['logserver.my.domain', 'logserver2.other.place:4444'],
              :failover_log_servers          => ['failover.my.domain', 'failover.other.place:4444'],
              :stream_driver                 => 'my_stream_driver',
              :stream_driver_mode            => 2,
              :stream_driver_auth_mode       => 'my_stream_driver/x509/name',
              :stream_driver_permitted_peers => '*.my.domain,*.other.place'
            }
          end

          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_tls_with_stream_driver_settings.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
          it { is_expected.not_to contain_notify("TLS StreamDriverPermittedPeers #{title}") }
        end

        context 'with rule and dest with an IP Address' do
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['1.2.3.4'],
            }
          end

          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_tls_with_peers_undef_ip_for_logserver.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
          it { is_expected.to contain_notify("TLS StreamDriverPermittedPeers #{title}") }
        end

        context 'with rule, hostname dest, and failover with an IP address' do
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['logserver1.my.domain'],
              :failover_log_servers => ['1.2.3.4'],
            }
          end

          let(:expected) { File.read("spec/expected/el#{os_facts[:operatingsystemmajrelease]}/remote_tls_with_peers_undef_ip_for_failover.txt") }

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(expected)}
          it { is_expected.to contain_notify("TLS StreamDriverPermittedPeers #{title}") }
        end
      end

      context 'when content specified' do
        let(:params) do
          {
            :content => "if (\$programname == 'audispd') then stop\n",
          }
          end

        it { is_expected.to compile.with_all_deps }
        it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(
         "if ($programname == 'audispd') then stop\n"
        ) }
      end

      context 'when neither content nor rule specified' do
        let(:params) do
          { }
        end

        it { is_expected.to_not compile.with_all_deps }
      end

      context 'when rule is specified but no destinations are specified' do
        let(:params) do
          { :rule => 'test_rule'}
        end

        it { is_expected.to_not compile.with_all_deps }
      end
    end
  end
end
