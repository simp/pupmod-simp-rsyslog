# **NOTE: THIS IS A [PRIVATE](https://github.com/puppetlabs/puppetlabs-stdlib#assert_private) CLASS**
#
# Ensures that there are PKI certificates readable by the rsyslog user in
# ``/etc/rsyslog.d/pki``
#
class rsyslog::config::pki (
  $external_pki_source = simplib::lookup('simp_options::pki::source', { 'default_value' => '/etc/pki' })
){
  assert_private()

  if $::rsyslog::pki {
    if $::rsyslog::pki == 'simp' { include '::pki' }

    pki::copy { $::rsyslog::pki_base_dir:
      source => $external_pki_source
    }
  }
  else {
    file { "${::rsyslog::pki_base_dir}/pki":
      ensure => 'directory',
      owner  => 'root',
      group  => 'root',
      mode   => '0640'
    }
  }
}
