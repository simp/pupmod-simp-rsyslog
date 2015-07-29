require 'spec_helper'

describe 'rsyslog::global' do

  base_facts = {
    "RHEL 6" => {
      :fqdn => 'spec.test',
      :grub_version => '0.97',
      :hardwaremodel => 'x86_64',
      :interfaces => 'lo',
      :ipaddress_lo => '127.0.0.1',
      :lsbmajdistrelease => '6',
      :operatingsystem => 'RedHat',
      :operatingsystemmajrelease => '6',
      :processorcount => 4,
      :uid_min => '500',
      :memorysize_mb => 1024
    },
    "RHEL 7" => {
      :fqdn => 'spec.test',
      :grub_version => '0.97',
      :hardwaremodel => 'x86_64',
      :interfaces => 'lo',
      :ipaddress_lo => '127.0.0.1',
      :lsbmajdistrelease => '7',
      :operatingsystem => 'RedHat',
      :operatingsystemmajrelease => '7',
      :processorcount => 4,
      :uid_min => '500',
      :memorysize_mb => 1024
    }
  }

  shared_examples_for "a fact set" do
    it { should create_class('rsyslog::global') }

    context 'base' do
      it { should compile.with_all_deps }
      it { should contain_class('rsyslog') }
      it { should contain_class('tcpwrappers') }

      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueSize 20971/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueHighWatermark 20552/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueLowWatermark 14680/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueDiscardMark 41942/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueWorkerThreadMinimumMessages 1747/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueWorkerThreads 3/) }
      it { should create_concat_fragment('rsyslog+global').with_content(/MainMsgQueueMaxDiskSpace 20M/) }

      it { should create_file('/etc/sysconfig/rsyslog') }

      context 'actionSendStreamDriverPermittedPeers should be optional' do
        let(:params) {{ :actionSendStreamDriverPermittedPeers => [] }}

        it { should compile.with_all_deps }
      end
    end
  end

  describe "RHEL 6" do
    it_behaves_like "a fact set"
    let(:facts) {base_facts['RHEL 6']}
  end

  describe "RHEL 7" do
    it_behaves_like "a fact set"
    let(:facts) {base_facts['RHEL 7']}
  end
end
