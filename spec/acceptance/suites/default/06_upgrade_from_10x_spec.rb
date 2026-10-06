require 'spec_helper_acceptance'

test_name 'upgrade from simp/rsyslog 10.x'

# Each scenario starts from a node configured by simp/rsyslog 10.0.1 with its
# defaults, then applies this module.
describe 'upgrading from simp/rsyslog 10.x' do
  let(:client) { only_host_with_role(hosts, 'client') }
  let(:global_conf) { '/etc/rsyslog.simp.d/00_simp_pre_logging/global.conf' }

  def modulepath_10x(host)
    "/root/rsyslog10:#{on(host, 'puppet config print modulepath --environment production').stdout.strip}"
  end

  def configure_10x(host)
    on(host, 'rm -rf /etc/rsyslog.simp.d /etc/systemd/system/rsyslog.service.d /etc/rsyslog.conf')
    on(host, 'dnf reinstall -y rsyslog && systemctl daemon-reload')
    set_hieradata_on(host, {})
    apply_manifest_on(host, "class { 'rsyslog': }", modulepath: modulepath_10x(host), catch_failures: true)
    on(host, "test -f #{global_conf}")
  end

  def expect_logging(host)
    on(host, 'systemctl restart rsyslog')
    message = "UPGRADE_#{Time.now.to_f.to_s.tr('.', '_')}"
    on(host, "logger -t upgrade #{message}")
    wait_for_log_message(host, '/var/log/messages', message)
  end

  it 'installs simp/rsyslog 10.0.1' do
    on(client, 'puppet module install simp-rsyslog --version 10.0.1 --ignore-dependencies --target-dir /root/rsyslog10')
  end

  context 'with a bare include and no profile' do
    it 'leaves the 10.x configuration as it is' do
      configure_10x(client)
      before = on(client, 'md5sum /etc/rsyslog.conf').stdout

      apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)

      expect(on(client, 'md5sum /etc/rsyslog.conf').stdout).to eq(before)
      on(client, "test -f #{global_conf}")
      expect_valid_rsyslog_config(client)
      expect_logging(client)
    end
  end

  context 'with one setting and no profile' do
    it 'replaces global.conf and keeps the inputs' do
      configure_10x(client)
      set_hieradata_on(client, { 'rsyslog::config::net_enable_dns' => false })

      apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)

      on(client, "test ! -e #{global_conf}")
      on(client, 'test -f /etc/rsyslog.simp.d/00_simp_pre_logging/31_imuxsock.conf')
      expect_valid_rsyslog_config(client)
      expect_logging(client)
    end
  end

  context 'with purge_rule_dir and no profile' do
    it 'keeps rsyslog working' do
      configure_10x(client)
      set_hieradata_on(client, { 'rsyslog::config::purge_rule_dir' => true })

      apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)

      on(client, "test ! -e #{global_conf}")
      on(client, 'test -f /etc/rsyslog.simp.d/99_simp_local/ZZ_default.conf')
      expect_valid_rsyslog_config(client)
      expect_logging(client)
    end
  end

  [true, false].each do |purge|
    context "with simp:defaults and purge_rule_dir=#{purge}" do
      it 'keeps rsyslog working' do
        configure_10x(client)
        set_hieradata_on(client, SIMP_DEFAULTS.merge('rsyslog::config::purge_rule_dir' => purge))

        apply_manifest_on(client, "include 'rsyslog'", catch_failures: true)
        apply_manifest_on(client, "include 'rsyslog'", catch_changes: true)

        on(client, "test ! -e #{global_conf}")
        expect_valid_rsyslog_config(client)
        expect_logging(client)
      end
    end
  end
end
