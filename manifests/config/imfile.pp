# @summary Load the `imfile` input module
#
# Included by `rsyslog::rule::data_source`, whose `input(type="imfile" ...)`
# rules need the module, and by `rsyslog::config` when
# `rsyslog::config::replace_rsyslog_conf` is `true`.
#
# @api private
#
class rsyslog::config::imfile {
  assert_private()

  include 'rsyslog'

  rsyslog::config::statement { '33_imfile':
    header => 'module(load="imfile"',
    params => pick($rsyslog::config::extra_imfile_mod_params, {}),
    create => true,
  }
}
