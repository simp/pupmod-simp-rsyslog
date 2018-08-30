require 'spec_helper'

describe 'rsyslog::rule::remote' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:title) do
          'test_name'
        end

        let(:facts) do
          os_facts
        end

        context 'with rule and default parameters' do
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['1.2.3.4','5.6.7.8:5678']
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(<<EOM
ruleset(
  name="ruleset_test_name"
## TODO: Implement these once DA queues work properly inside of rulesets.
#  queue.filename="test_name_disk_queue"
#  queue.dequeuebatchsize="16"
#  queue.lowwatermark="2000"
#  queue.discardmark="9750"
#  queue.discardseverity="8"
#  queue.syncqueuefiles="off"
#  queue.type="LinkedList"
#  queue.workerthreads="1"
#  queue.timeoutshutdown="0"
#  queue.timeoutactioncompletion="1000"
#  queue.timeoutenqueue="2000"
#  queue.timeoutworkerthreadshutdown="60000"
#  queue.workerthreadminimummessages="100"
#  queue.maxfilesize="1m"
#  queue.saveonshutdown="on"
#  queue.dequeueslowdown="0"
) {
  action(
    type="omfwd"
    protocol="tcp"
    target="1.2.3.4"
    port="514"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    ResendLastMSGOnReconnect="on"
  )
  action(
    type="omfwd"
    protocol="tcp"
    target="5.6.7.8"
    port="5678"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    ResendLastMSGOnReconnect="on"
  )
}

if (test_rule) then call ruleset_test_name
EOM
          ) }
        end

        context 'with rule and all optional params specified' do
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
              :stream_driver                        => 'my_stream_driver',
              :stream_driver_mode                   => 2,
              :stream_driver_auth_mode              => 'my_stream_driver/x509/name',
              :stream_driver_permitted_peers        => "*.${::domain}",
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

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(<<EOM
ruleset(
  name="ruleset_test_name"
## TODO: Implement these once DA queues work properly inside of rulesets.
#  queue.filename="my_queue"
#  queue.size="1000"
#  queue.dequeuebatchsize="100"
#  queue.maxdiskspace="100000"
#  queue.highwatermark="900"
#  queue.lowwatermark="200"
#  queue.fulldelaymark="940"
#  queue.lightdelaymark="300"
#  queue.discardmark="975"
#  queue.discardseverity="7"
#  queue.checkpointinterval="2"
#  queue.syncqueuefiles="on"
#  queue.type="LinkedList"
#  queue.workerthreads="2"
#  queue.timeoutshutdown="1"
#  queue.timeoutactioncompletion="100"
#  queue.timeoutenqueue="200"
#  queue.timeoutworkerthreadshutdown="6000"
#  queue.workerthreadminimummessages="10"
#  queue.maxfilesize="2m"
#  queue.saveonshutdown="on"
#  queue.dequeueslowdown="0"
#  queue.dequeuetimebegin="1"
#  queue.dequeuetimeend="2"
) {
  action(
    type="omfwd"
    template="my_template"
    protocol="relp"
    target="1.2.3.4"
    port="514"
    TCP_Framing="octet-counted"
    ZipLevel="1"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="6"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="single"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="off"
    RebindInterval="1"
    ResendLastMSGOnReconnect="off"
  )

  action(
    type="omfwd"
    template="my_template"
    protocol="relp"
    target="5.6.7.8"
    port="5678"
    TCP_Framing="octet-counted"
    ZipLevel="1"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="6"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="single"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="off"
    RebindInterval="1"
    ResendLastMSGOnReconnect="off"
    action.resumeRetryCount="1"
    action.execOnlyWhenPreviousIsSuspended="on"
  )

  action(
    type="omfwd"
    template="my_template"
    protocol="relp"
    target="9.10.11.12"
    port="514"
## NOTE: This must exist for the last failover host so that we can queue logs to disk when needed.
    queue.filename="my_queue_action"
    queue.size="1000"
    queue.dequeuebatchsize="100"
    queue.maxdiskspace="100000"
    queue.highwatermark="900"
    queue.lowwatermark="200"
    queue.fulldelaymark="940"
    queue.lightdelaymark="300"
    queue.discardmark="975"
    queue.discardseverity="7"
    queue.checkpointinterval="2"
    queue.syncqueuefiles="on"
    queue.type="LinkedList"
    queue.workerthreads="2"
    queue.timeoutshutdown="1"
    queue.timeoutactioncompletion="100"
    queue.timeoutenqueue="200"
    queue.timeoutworkerthreadshutdown="6000"
    queue.workerthreadminimummessages="10"
    queue.maxfilesize="2m"
    queue.saveonshutdown="on"
    queue.dequeueslowdown="0"
    queue.dequeuetimebegin="1"
    queue.dequeuetimeend="2"
    TCP_Framing="octet-counted"
    ZipLevel="1"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="6"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="single"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="off"
    RebindInterval="1"
    ResendLastMSGOnReconnect="off"
    action.resumeRetryCount="1"
    action.execOnlyWhenPreviousIsSuspended="on"
  )
  stop
}

if (test_rule) then call ruleset_test_name
EOM
          ) }
        end

        context 'with rule and and TLS turned on and default values' do
          let(:hieradata) { "rsyslog_tls" }
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['logserver.my.domain', 'logserver2.other.place:4444'],
              :failover_log_servers => ['failover.my.domain', 'failover.other.place:4444']
            }
          end
          let(:precondition) do
            'include rsyslog'
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('10_simp_remote/test_name.conf').with_content(<<EOM
ruleset(
  name="ruleset_test_name"
## TODO: Implement these once DA queues work properly inside of rulesets.
#  queue.filename="test_name_disk_queue"
#  queue.dequeuebatchsize="16"
#  queue.lowwatermark="2000"
#  queue.discardmark="9750"
#  queue.discardseverity="8"
#  queue.syncqueuefiles="off"
#  queue.type="LinkedList"
#  queue.workerthreads="1"
#  queue.timeoutshutdown="0"
#  queue.timeoutactioncompletion="1000"
#  queue.timeoutenqueue="2000"
#  queue.timeoutworkerthreadshutdown="60000"
#  queue.workerthreadminimummessages="100"
#  queue.maxfilesize="1m"
#  queue.saveonshutdown="on"
#  queue.dequeueslowdown="0"
) {
  action(
    type="omfwd"
    protocol="tcp"
    target="logserver.my.domain"
    port="6514"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="logserver.my.domain"
    ResendLastMSGOnReconnect="on"
  )
  action(
    type="omfwd"
    protocol="tcp"
    target="logserver2.other.place"
    port="4444"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="logserver2.other.place"
    ResendLastMSGOnReconnect="on"
  )

  action(
    type="omfwd"
    protocol="tcp"
    target="failover.my.domain"
    port="6514"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="failover.my.domain"
    ResendLastMSGOnReconnect="on"
    action.resumeRetryCount="-1"
    action.execOnlyWhenPreviousIsSuspended="on"
  )

  action(
    type="omfwd"
    protocol="tcp"
    target="failover.other.place"
    port="4444"
## NOTE: This must exist for the last failover host so that we can queue logs to disk when needed.
    queue.filename="test_name_disk_queue_action"
    queue.dequeuebatchsize="16"
    queue.lowwatermark="2000"
    queue.discardmark="9750"
    queue.discardseverity="8"
    queue.syncqueuefiles="off"
    queue.type="LinkedList"
    queue.workerthreads="1"
    queue.timeoutshutdown="0"
    queue.timeoutactioncompletion="1000"
    queue.timeoutenqueue="2000"
    queue.timeoutworkerthreadshutdown="60000"
    queue.workerthreadminimummessages="100"
    queue.maxfilesize="1m"
    queue.saveonshutdown="on"
    queue.dequeueslowdown="0"
    TCP_Framing="traditional"
    ZipLevel="0"
## TODO: Implement this once we upgrade to v7-stable or later.
#    maxErrorMessages="5"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.mode="none"
## TODO: Implement this once we upgrade to v7-stable or later.
#    compression.stream.flushOnTXEnd="on"
    StreamDriverMode="1"
    StreamDriverAuthMode="x509/name"
    StreamDriverPermittedPeers="failover.other.place"
    ResendLastMSGOnReconnect="on"
    action.resumeRetryCount="-1"
    action.execOnlyWhenPreviousIsSuspended="on"
  )
}

if (test_rule) then call ruleset_test_name
EOM
          ) }
        end

        context 'with TLS turned on and destination set to IP Address' do
          let(:hieradata) { "rsyslog_tls" }
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['1.2.3.4'],
            }
          end
          let(:precondition) do
            'include rsyslog'
          end

          it { is_expected.to_not compile.with_all_deps }
        end

        context 'with TLS turned on and failover set to IP address' do
          let(:hieradata) { "rsyslog_tls" }
          let(:params) do
            {
              :rule => 'test_rule',
              :dest => ['logserver1.my.domain'],
              :failover_log_server => ['1.2.3.4'],
              :stream_driver => "gtls",
            }
          end
          let(:precondition) do
            'include rsyslog'
          end

          it { is_expected.to_not compile.with_all_deps }
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
end
