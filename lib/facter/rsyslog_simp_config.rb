# frozen_string_literal: true

# _Description_
#
# Reports the state of the rsyslog configuration this module manages, so the
# module can tell a node configured by an earlier version (or with
# rsyslog::config::replace_rsyslog_conf) from one using the package's
# /etc/rsyslog.conf, and can remove settings and listeners without creating
# files that do not exist yet.
#
# Only reads files.
#
# * conf_managed: /etc/rsyslog.conf was written by this module
# * rule_dir:     the rule directory /etc/rsyslog.conf includes
# * pre_logging:  the files in <rule_dir>/00_simp_pre_logging
# * inputs:       the input(type=... port=...) listeners those files define
#
Facter.add('rsyslog_simp_config') do
  confine { File.exist?('/etc/rsyslog.conf') }

  setcode do
    conf = File.read('/etc/rsyslog.conf')

    rule_dir = conf.scan(%r{^\s*\$IncludeConfig\s+(\S+)/\*\.conf\s*$}).flatten.find { |dir| dir != '/etc/rsyslog.d' }
    rule_dir ||= '/etc/rsyslog.simp.d'

    pre_logging = Dir.glob(File.join(rule_dir, '00_simp_pre_logging', '*.conf')).sort

    inputs = pre_logging.flat_map do |path|
      File.read(path).scan(%r{^\s*input\(type="(\w+)"[^)]*\bport="(\d+)"}).map do |type, port|
        { 'type' => type, 'port' => port.to_i }
      end
    rescue SystemCallError
      []
    end

    {
      'conf_managed' => conf.include?('managed by Puppet (simp/rsyslog module)'),
      'rule_dir'     => rule_dir,
      'pre_logging'  => pre_logging.map { |path| File.basename(path) },
      'inputs'       => inputs,
    }
  rescue SystemCallError
    nil
  end
end
