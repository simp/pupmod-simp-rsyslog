# @summary Install the TLS driver and set the global TLS stream driver settings
#
# Included by `rsyslog::config` when `rsyslog::enable_tls_logging` or
# `rsyslog::tls_tcp_server` is `true`, and by any `rsyslog::rule::remote`
# with `use_tls => true`.
#
# Each `rsyslog::config::default_net_stream_driver*` setting that is not set
# is written only when the file has no value for it yet, because TLS cannot
# work without them. A value replaces it, `auto` writes the computed default,
# and `absent` removes it.
#
# @api private
#
class rsyslog::config::tls {
  assert_private()

  include 'rsyslog'

  package { $rsyslog::tls_package_name:
    ensure  => $rsyslog::install::ensure,
    require => Class['rsyslog::install'],
    notify  => Class['rsyslog::service'],
  }

  $_fqdn = $facts['networking']['fqdn']
  $_computed = {
    'defaultNetstreamDriver'         => 'gtls',
    'defaultNetstreamDriverCAFile'   => "${rsyslog::app_pki_dir}/cacerts/cacerts.pem",
    'defaultNetstreamDriverCertFile' => "${rsyslog::app_pki_dir}/public/${_fqdn}.pub",
    'defaultNetstreamDriverKeyFile'  => "${rsyslog::app_pki_dir}/private/${_fqdn}.pem",
  }

  $_settings = {
    'defaultNetstreamDriver'         => $rsyslog::config::default_net_stream_driver,
    'defaultNetstreamDriverCAFile'   => $rsyslog::config::default_net_stream_driver_ca_file,
    'defaultNetstreamDriverCertFile' => $rsyslog::config::default_net_stream_driver_cert_file,
    'defaultNetstreamDriverKeyFile'  => $rsyslog::config::default_net_stream_driver_key_file,
  }

  $_params = $_settings.reduce({}) |$memo, $kv| {
    $kv[1] ? {
      undef   => $memo,
      'auto'  => $memo + { $kv[0] => $_computed[$kv[0]] },
      default => $memo + { $kv[0] => $kv[1] },
    }
  }

  # These must not be in the first global() statement (see
  # rsyslog::config), so they get a statement of their own.
  rsyslog::config::statement { '12_global_tls':
    header    => 'global(',
    params    => $_params,
    fallbacks => $_computed,
  }
}
