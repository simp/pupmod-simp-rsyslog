# == Class: rsyslog::install
#
# Installs the RSyslog packages necessary for use of RSyslog.
#
class rsyslog::install {
  assert_private()

  package { "${::rsyslog::package_name}.${::hardwaremodel}": ensure => 'latest' }

  # remove existing/conflicting packages
  if $::rsyslog::package_name == 'rsyslog7' {
    package { "rsyslog.${::hardwaremodel}": ensure => 'absent' }
    ->
    Package["${::rsyslog::package_name}.${::hardwaremodel}"]
  }


  # Some hackery to remove the i386 version of rsyslog if you're on a x86_64
  # system.
  if $::hardwaremodel == 'x86_64' {
    package { "${::rsyslog::package_name}.i386": ensure => 'absent' }
  }

  if $::rsyslog::enable_tls_logging {
    package { "${::rsyslog::tls_package_name}": ensure => 'latest', }
  }
}
