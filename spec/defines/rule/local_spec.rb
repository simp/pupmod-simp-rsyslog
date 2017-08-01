require 'spec_helper'

describe 'rsyslog::rule::local' do
  context 'supported operating systems' do
    on_supported_os.each do |os, os_facts|
      context "on #{os}" do
        let(:title) do
          'test_name'
        end

        let(:facts) do
          os_facts
        end
     
        context 'when only rule and target_log_file specified' do
          let(:params) do
            {
              :rule      => 'test_rule',
              :target_log_file => '/var/log/test_file'
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('99_simp_local/test_name.conf').with_content( <<EOM

if (test_rule) then {
  action(
    type="omfile"
    file="/var/log/test_file"
    dynaFileCacheSize="10"
    zipLevel="0"
    veryRobustZip="on"
    flushInterval="0"
    flushOnTXEnd="on"
    fileCreateMode="0644"
    dirCreateMode="0700"
    failOnChownFailure="on"
    createDirs="on"
    queue.dequeuebatchsize="16"
    queue.lowwatermark="2000"
    queue.discardmark="9750"
    queue.discardseverity="8"
    queue.syncqueuefiles="off"
    queue.type="Direct"
    queue.workerthreads="1"
    queue.timeoutshutdown="0"
    queue.timeoutactioncompletion="1000"
    queue.timeoutenqueue="2000"
    queue.timeoutworkerthreadshutdown="60000"
    queue.workerthreadminimummessages="100"
    queue.maxfilesize="1m"
    queue.saveonshutdown="off"
    queue.dequeueslowdown="0"
  )
}
EOM
          ) }
        end

        context 'when rule and target_log_file specified along with optional params' do
          let(:params) do
            {
              :rule                                 => 'test_rule',
              :target_log_file                      => '/var/log/test_file',
              :stop_processing                      => true,
              :template                             => 'my_template',
              :dyna_file_cache_size                 => 20,
              :zip_level                            => 1,
              :very_robust_zip                      => false,
              :flush_interval                       => 1,
              :async_writing                        => true,
              :flush_on_tx_end                      => false,
              :io_buffer_size                       => 10,
              :dir_owner                            => 'rsyslog_dir_user',
              :dir_owner_num                        => 100,
              :dir_group                            => 'rsyslog_dir_group',
              :dir_group_num                        => 200,
              :file_owner                           => 'rsyslog_file_user',
              :file_owner_num                       => 300,
              :file_group                           => 'rsyslog_file_group',
              :file_group_num                       => 400,
              :file_create_mode                     => '0640',
              :dir_create_mode                      => '0750',
              :fail_on_chown_failure                => false,
              :create_dirs                          => false,
              :sync                                 => true,
              :sig_provider                         => 'sig_provider',
              :cry_provider                         => 'cry_provider',
              :queue_filename                       => '/var/syslog/queue',
              :queue_spool_directory                => '/var/syslog/spool',
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
          it { is_expected.to contain_rsyslog__rule('99_simp_local/test_name.conf').with_content(<<EOM

if (test_rule) then {
  action(
    type="omfile"
    file="/var/log/test_file"
    template="my_template"
    dynaFileCacheSize="20"
    zipLevel="1"
    flushInterval="1"
    asyncWriting="on"
    ioBufferSize="10"
    dirOwner="rsyslog_dir_user"
    dirOwnerNum="100"
    dirGroup="rsyslog_dir_group"
    dirGroupNum="200"
    fileOwner="rsyslog_file_user"
    fileOwnerNum="300"
    fileGroup="rsyslog_file_group"
    fileGroupNum="400"
    fileCreateMode="0640"
    dirCreateMode="0750"
    sync="on"
    sig.provider="sig_provider"
    cry.provider="cry_provider"
    queue.filename="/var/syslog/queue"
    queue.spoolDirectory="/var/syslog/spool"
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
  )
  stop
}
EOM
          ) }
        end

        context 'when only rule and relative dyna_file specified' do
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

        context 'when full-path dyna_file specified' do
          let(:params) do
            {
              :rule      => 'test_rule',
              :dyna_file => '/var/log/%HOSTNAME%/test_file'
            }
          end
          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('99_simp_local/test_name.conf').with_content(
            /template\(name="#{title}" type="string" string="#{params[:dyna_file]}"\)\n\nif \(#{params[:rule]}\) then\s+{\n\s*action\(\n\s*type="omfile"\n\s*dynaFile="#{title}"/
          ) }
       end

        context 'when content specified' do
          let(:params) do
            {
              :content => "if (\$programname == 'audispd') then stop\n",
            }
          end

          it { is_expected.to compile.with_all_deps }
          it { is_expected.to contain_rsyslog__rule('99_simp_local/test_name.conf').with_content(
           "if ($programname == 'audispd') then stop\n"
          ) }
        end

        context 'when neither content nor rule specified' do
          let(:params) do
            {
              :target_log_file => '/var/log/test_file'
            }
          end

          it { is_expected.to_not compile.with_all_deps }
        end
      end
    end
  end
end
