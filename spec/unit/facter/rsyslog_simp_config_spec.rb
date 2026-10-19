# frozen_string_literal: true

require 'spec_helper'

describe 'custom fact rsyslog_simp_config' do
  subject(:fact) { Facter.fact('rsyslog_simp_config').value }

  let(:pre_logging) { '/etc/rsyslog.simp.d/00_simp_pre_logging' }

  before(:each) do
    Facter.clear
    allow(File).to receive(:exist?).and_call_original
    allow(File).to receive(:exist?).with('/etc/rsyslog.conf').and_return(true)
    allow(File).to receive(:read).and_call_original
    allow(File).to receive(:read).with('/etc/rsyslog.conf').and_return(rsyslog_conf)
    allow(Dir).to receive(:glob).and_call_original
    allow(Dir).to receive(:glob).with("#{pre_logging}/*.conf").and_return(files.keys.map { |f| "#{pre_logging}/#{f}" })
    files.each { |f, content| allow(File).to receive(:read).with("#{pre_logging}/#{f}").and_return(content) }
  end

  context 'with the rsyslog.conf this module writes' do
    let(:rsyslog_conf) do
      <<~EOM
        # This file is managed by Puppet (simp/rsyslog module).
        # Any changes will be overwritten.
        $IncludeConfig /etc/rsyslog.simp.d/*.conf
      EOM
    end
    let(:files) do
      {
        '40_imptcp.conf' => %(module(load="imptcp"\n)\ninput(type="imptcp" port="514")\n),
        '41_imtcp.conf' => %(module(load="imtcp"\n  StreamDriver.Mode="1"\n)\ninput(type="imtcp" port="6514")\n),
        '42_imudp.conf' => %(module(load="imudp"\n)\ninput(type="imudp" address="127.0.0.1" port="514")\n),
        'global.conf' => %(module(load="imklog")\n),
      }
    end

    it do
      is_expected.to eq(
        'conf_managed' => true,
        'rule_dir'     => '/etc/rsyslog.simp.d',
        'pre_logging'  => ['40_imptcp.conf', '41_imtcp.conf', '42_imudp.conf', 'global.conf'],
        'inputs'       => [
          { 'type' => 'imptcp', 'port' => 514 },
          { 'type' => 'imtcp', 'port' => 6514 },
          { 'type' => 'imudp', 'port' => 514 },
        ],
      )
    end
  end

  context "with the package's rsyslog.conf" do
    let(:rsyslog_conf) do
      <<~EOM
        global(workDirectory="/var/lib/rsyslog")
        include(file="/etc/rsyslog.d/*.conf" mode="optional")
        $IncludeConfig /etc/rsyslog.simp.d/*.conf
      EOM
    end
    let(:files) { {} }

    it do
      is_expected.to eq(
        'conf_managed' => false,
        'rule_dir'     => '/etc/rsyslog.simp.d',
        'pre_logging'  => [],
        'inputs'       => [],
      )
    end
  end
end
