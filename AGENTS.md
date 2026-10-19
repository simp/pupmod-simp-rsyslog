# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-rsyslog` is a SIMP Puppet module that installs, configures, and manages
**Rsyslog version 8** on Enterprise Linux systems. A bare `include rsyslog`
installs the package and nothing else; every other behavior is opt-in through
a parameter (see "Blast radius and the `simp:defaults` profile" below). When
configured, it writes numbered `.conf` fragments to a SIMP-owned directory
(`/etc/rsyslog.simp.d`) so that rule ordering is deterministic, and hooks that
directory into rsyslog either with one `$IncludeConfig` line in the package's
`/etc/rsyslog.conf` or, with `replace_rsyslog_conf`, by replacing that file. On top of the base
client configuration it layers a server role (listeners for TCP, TLS-TCP, and
UDP), TLS/PKI for encrypted log transport, optional `logrotate`, and — for a
server — optional `iptables` and SELinux integration.

The configuration is deliberately slanted toward the quirks of the Rsyslog
builds shipped with Enterprise Linux (`manifests/init.pp`). It targets
Rsyslog 8-stable and emits a runtime `warning` if the installed `rsyslogd` is
older than `8.24.0`, pointing the operator at module version `7.6.4` instead
(`manifests/init.pp`). The installed version is discovered by a custom
fact (`lib/facter/rsyslogd.rb`) that parses `rsyslogd -v`.

Everything is driven through a rich set of defined types: rules
(`rsyslog::rule` and its typed wrappers) and templates
(`rsyslog::template::*`). Rules are dropped into numbered subdirectories of
`$rule_dir` so their evaluation order is fixed. The directory is purged only
when `rsyslog::config::purge_rule_dir` is `true`; otherwise rules are removed
with `ensure => absent`.

## Blast radius and the `simp:defaults` profile

Since 11.0.0 every setting is independently enforceable:

- `undef` (the default) leaves the setting alone; a value sets it; `absent`
  (or `false` for Boolean toggles) removes it. Never add a parameter whose
  unset value writes something.
- Global settings live in `00_simp_pre_logging/<NN>_<statement>.conf`. A
  multi-parameter statement (`global(`, `module(load=...`, `main_queue(`) is
  a file created once with `replace => false` (`rsyslog::config::block`),
  and each parameter is its own `file_line` inserted after the header line
  (`rsyslog::config::param`, `rsyslog::config::statement`). A
  single-setting statement is a whole `rsyslog::rule` file. Never render a
  file that holds several independent settings from a template.
- Rsyslog rejects a second load of a module, a repeated `global()` key and a
  second `main_queue()`. The package's `/etc/rsyslog.conf` already loads
  `imuxsock`, `imjournal` and `omfile` and sets `workDirectory`, so the
  parameters for those only take effect with `replace_rsyslog_conf` and
  otherwise warn (`$_package_conf_settings` in `config.pp`).
- Values that rsyslog needs to run safely (TLS driver/cert paths, a TLS
  listener's `AuthMode`/`PermittedPeer`, imjournal's `StateFile`) are
  written as `fallbacks` with `replace => false`. Values that used to be
  computed from facts are available with `auto`.
- `SIMP/compliance_profiles/` ships the `simp:defaults` profile, which
  restores the 10.x defaults, destructive ones included.
  `spec/classes/simp_defaults_profile_spec.rb` renders the files the catalogue
  would write (`spec/lib/rendered_config.rb`) and compares them with the
  complete 10.x `global.conf` files in `spec/classes/expected/`. Add a check
  there for any new parameter whose behavior changes the old default.

## Business logic

### Class graph

The public entry class is `rsyslog` (`manifests/init.pp`). It `contain`s the
three private worker classes and pins their ordering
(`manifests/init.pp`):

```
Class['rsyslog::install'] -> Class['rsyslog::config'] ~> Class['rsyslog::service']
```

- **`rsyslog` (`manifests/init.pp`)** — Public class; consumers
  `include 'rsyslog'`. Holds the client-facing parameters: package/service
  names, `trusted_nets`, `log_servers` / `failover_log_servers`, the listener
  toggles (`tcp_server`, `tls_tcp_server`, `udp_server`) and their ports,
  `enable_tls_logging`, `pki`, `logrotate`, and a `rules` hash. When
  `$logrotate` is true it additionally `contain`s
  `rsyslog::config::logrotate` after the service
  (`manifests/init.pp`). It iterates `$rules` and declares a
  `rsyslog::rule` per entry via the splat operator
  (`manifests/init.pp`), which is how rules can be created purely from
  Hiera.
- **`rsyslog::install` (`manifests/install.pp`)** — `assert_private()`
  (`install.pp`). Installs the core package and handles i386-on-x86_64
  package removal. The TLS package is installed by `rsyslog::config::tls`.
- **`rsyslog::config` (`manifests/config.pp`)** — `assert_private()`
  (`config.pp`). The heart of the module. Declares nothing when every
  parameter is unset. Otherwise writes the `00_simp_pre_logging` settings,
  the `SYSLOGD_OPTIONS` line in `/etc/sysconfig/rsyslog`, the `LimitNOFILE`
  systemd drop-in, `99_simp_local/ZZ_default.conf` (`enable_default_rules`)
  and, with `replace_rsyslog_conf`, a replaced `/etc/rsyslog.conf`
  (`rsyslog::config::rule_tree`). It carries the bulk of the tunable
  parameters (imuxsock `SysSock.*`, main-message-queue sizing, TLS stream
  driver settings, `imtcp` keep-alive, DNS/ACL behavior) and the PKI branch.
  Private helpers: `config::rule_tree` (rule directory and the
  `rsyslog.conf` hook), `config::tls` (TLS package and driver globals),
  `config::imfile`, `config::failover_hack`, and the `config::block`,
  `config::param`, `config::statement` and `config::line` defines.
- **`rsyslog::service` (`manifests/service.pp`)** — `assert_private()`
  (`service.pp`). Declares the service only when `rsyslog::service_ensure`
  or `rsyslog::service_enable` (or the deprecated `rsyslog::service::enable`)
  is set. Otherwise, with `rsyslog::restart_on_change`, a refresh-only
  `systemctl try-restart` exec. Every configuration resource notifies this
  class, which is always contained.
- **`rsyslog::config::logrotate` (`manifests/config/logrotate.pp`)** —
  `assert_private()` (`config/logrotate.pp`); asserts the optional
  `simp/logrotate` dependency (`config/logrotate.pp`) and proxies its
  parameters to a `logrotate::rule` for the syslog logs.

### Server role

`rsyslog::server` (`manifests/server.pp`) is the entry point for a host
that must **receive** logs. It `include`s `rsyslog` and then conditionally
`contain`s three private helpers based on `simp_options` toggles:

- **`rsyslog::server::firewall`** — `assert_private()`; asserts the optional
  `simp/iptables` dependency (`manifests/server/firewall.pp`). Opens the
  enabled listener ports (TLS-TCP, TCP, UDP) to `$rsyslog::trusted_nets`.
  Enabled by `simp_options::firewall`.
- **`rsyslog::server::selinux`** — `assert_private()`
  (`manifests/server/selinux.pp`). Sets the `nis_enabled` SELinux boolean when
  SELinux is not disabled. Enabled only by `enable_selinux: true`
  (`server.pp`; the `simp:defaults` profile sets it when
  `os.selinux.enforced`); ordered **before** the service.

### Rules and templates (defined types)

Rules are `.conf` fragments written into numbered subdirectories of
`$rule_dir` (`/etc/rsyslog.simp.d`); the leading numeric prefix fixes their
evaluation order. `rsyslog::rule` (`manifests/rule.pp`) is the base define —
it validates the rule name (no absolute path, at most one `/`) and writes the
fragment. The typed wrappers set the correct priority prefix and render the
right syntax:

- `rsyslog::rule::console` → `06_simp_console` (omusrmsg to logged-in users)
- `rsyslog::rule::data_source` → `05_simp_data_sources` (input modules, e.g.
  `imfile`)
- `rsyslog::rule::drop` → `07_simp_drop_rules` (`if (…) then stop`)
- `rsyslog::rule::local` → `99_simp_local` (local file destinations; extensive
  queue-parameter validation, renders `templates/rule/local.epp`)
- `rsyslog::rule::other` → `20_simp_other` (arbitrary, unstructured rules)
- `rsyslog::rule::remote` → `10_simp_remote` (forward to remote servers; TLS,
  compression, disk-assisted queues, IP-vs-hostname peer handling)

Templates map to the four Rsyslog template kinds, each written under
`05_simp_templates`: `rsyslog::template::list`, `::plugin`, `::string`, and
`::subtree`.

## Gotchas / non-obvious details

- **The rule directory is purged only on request.** With
  `rsyslog::config::purge_rule_dir: true` (set by `simp:defaults`), `$rule_dir`
  and each rule subdirectory are declared with `recurse`, `purge` and `force`
  (`config/rule_tree.pp`, `rule/directory.pp`), so any `.conf` not managed by
  an `rsyslog::rule` is deleted on the next run.
- **Rule ordering is encoded in directory-number prefixes.** The `NN_simp_*`
  prefixes (`00_simp_pre_logging`, `05_*`, `06_*`, `07_*`, `09_failover_hack`,
  `10_simp_remote`, `20_simp_other`, `99_simp_local`) exist so `$IncludeConfig
  *.conf` evaluates them in the intended order. Preserve these prefixes when
  adding rule types.
- **The `09_failover_hack` rule is load-bearing.** Rsyslog will not parse a
  failover action definition unless at least one rule already exists, so the
  module emits a no-op `continue` rule first (`config/failover_hack.pp`,
  included by every `rsyslog::rule::remote` and with `replace_rsyslog_conf`).
  Don't remove it.
- **Versions older than 8.24.0 are unsupported.** the `rsyslog` class warns and
  points at module `7.6.4` (`init.pp`). This gate depends on the
  custom `rsyslogd` fact (`lib/facter/rsyslogd.rb`) being present.
- **TLS is inferred, not just toggled.** `imtcp_stream_driver_mode` is derived:
  it is `'1'` when any of `$rsyslog::pki`, `$rsyslog::tls_tcp_server`, or
  `$rsyslog::enable_tls_logging` is set, else `'0'` (`config.pp`); the
  auth mode then defaults from that (`anon` vs `x509/name`,
  `config.pp`). The CA/cert/key paths default under `$app_pki_dir`
  (`/etc/pki/simp_apps/rsyslog/x509`) and are the **only** way to set the TLS
  material (`config/tls.pp`). `rsyslog::rule::remote`'s `use_tls` overrides
  `enable_tls_logging` per rule; `false` writes `StreamDriver="ptcp"`.
- **PKI is gated behind an optional dependency.** `rsyslog::config` only pulls
  in PKI when `$rsyslog::pki` is truthy, and asserts `simp/pki` at runtime
  before calling `pki::copy` (`config.pp`). `pki` accepts `'simp'`,
  `true`, or `false` with distinct meanings (see the `@param pki` docs in
  `init.pp`).
- **Several parameters are deprecated but still wired.** `rsyslog::config`
  emits `warning`s for `default_template`, `action_send_stream_driver_mode`,
  `action_send_stream_driver_auth_mode`, `suppress_noauth_warn`, and
  `disable_remote_dns`, each pointing at its replacement
  (`config.pp`). Prefer the replacements
  (`default_file_template`, `imtcp_stream_driver_*`, `net_permit_acl_warning`,
  `net_enable_dns`).
- **Queue sizing is fact-derived math, on request.** With `auto`, the
  main-message-queue size and its high/low/discard watermarks and
  worker-thread counts are computed from `memory.system.total_bytes` and
  `processors.count` (`config.pp`); the per-rule `local`/`remote` defines re-validate
  supplied queue parameters against each other.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` appears only as a fixture
  (`.fixtures.yml`).
- **`compliance_engine` is a test fixture, not a dependency.** It is in
  `.fixtures.yml` only so the profile specs can resolve
  `compliance_engine::enforcement`. Don't add it to `metadata.json`. On Ruby
  >= 3.4 its library needs the `observer` gem, which the puppetsync `Gemfile`
  does not include; add it locally with a `Gemfile.local`.

## The `simp_options` / `simplib::lookup` seam

This is the module's real business-logic seam — the SIMP-wide feature toggles
that let one Hiera setting drive many modules. All calls pass an explicit
`default_value` so the module works even when `simp_options` is not included:

| Location | Key | `default_value` |
|----------|-----|-----------------|
| `init.pp` | `simp_options::trusted_nets` | `['127.0.0.1/32']` |
| `init.pp` | `simp_options::syslog::log_servers` | `[]` |
| `init.pp` | `simp_options::syslog::failover_log_servers` | `[]` |
| `init.pp` | `simp_options::logrotate` | `false` |
| `init.pp` | `simp_options::pki` | `false` |
| `init.pp` | `simp_options::pki::source` | `'/etc/pki/simp/x509'` |
| `server.pp` | `simp_options::firewall` | `false` |

`simp_options::package_ensure` is also consumed elsewhere in the SIMP
ecosystem; keep routing SIMP feature toggles through
`simplib::lookup('simp_options::*', { 'default_value' => … })` with an
explicit default rather than assuming `simp_options` is included.

## Dependencies

Hard dependencies (from `metadata.json`):

- `puppet/systemd` `>= 4.0.2 < 9.0.0` — provides `systemd::dropin_file` (used
  for the EL7 override).
- `puppetlabs/stdlib` `>= 8.0.0 < 10.0.0`.
- `simp/simplib` `>= 4.9.0 < 5.0.0` — provides `simplib::lookup`,
  `simplib::assert_optional_dependency`, the `Simplib::*` data types, and
  supporting facts.

Optional dependencies (from `metadata.json` `simp.optional_dependencies`) —
each is asserted at runtime with `simplib::assert_optional_dependency` only
when the corresponding feature is enabled, so they are **not** required to be
installed unless you use that feature:

- `simp/pki` `>= 6.2.0 < 7.0.0` — asserted at `manifests/config.pp` when
  `$rsyslog::pki`.
- `simp/logrotate` `>= 6.5.0 < 7.0.0` — asserted at
  `manifests/config/logrotate.pp`.
- `simp/iptables` `>= 6.5.3 < 8.0.0` — asserted in
  `manifests/server/firewall.pp`.

Runtime requirement (from `metadata.json` `requirements`): `puppet
>= 7.0.0 < 9.0.0`. Note this module is on the **older** baseline — the
requirement names `puppet`, not `openvox`. (SIMP is migrating Puppet →
OpenVox; if `metadata.json` later switches this to `openvox`, update this line
to match.)

Supported OS matrix (from `metadata.json`): CentOS 7/8/9; RedHat 7/8/9;
OracleLinux 7/8/9; Rocky 8/9; AlmaLinux 8/9.

## Repository layout

- `manifests/init.pp` — the public `rsyslog` class (client parameters, the
  install→config→service chain, the `rules` Hiera hash iterator).
- `manifests/install.pp`, `manifests/service.pp` — private install/service
  workers.
- `manifests/config.pp` — private; the bulk of the configuration logic and
  tunables.
- `manifests/config/logrotate.pp` — private; optional logrotate integration.
- `manifests/server.pp` — the `rsyslog::server` role class.
- `manifests/server/{firewall,selinux}.pp` — private server-role helpers.
- `manifests/rule.pp` + `manifests/rule/{console,data_source,drop,local,other,remote}.pp`
  — the rule defined types.
- `manifests/template/{list,plugin,string,subtree}.pp` — the template defined
  types.
- `types/boolean.pp` — `Rsyslog::Boolean = Variant[Enum['on','off'],Boolean]`.
- `types/options.pp` — `Rsyslog::Options = Hash[String,Variant[Numeric,String]]`.
- `types/queuetype.pp` — `Rsyslog::QueueType =
  Enum['FixedArray','LinkedList','Direct','Disk']`.
- `manifests/config/*.pp` — private helpers (see `rsyslog::config` above).
- `functions/format_value.pp` — renders Booleans as `on`/`off`.
- `SIMP/compliance_profiles/` — the `simp:defaults` profile and its checks.
- `templates/rule/local.epp`, `templates/rule/remote.epp` — rule bodies.
- `lib/facter/rsyslogd.rb` — custom fact parsing `rsyslogd -v` into
  `{ version, features }`; drives the version gate in `init.pp`.
- `metadata.json` — deps, optional deps, OS matrix, Puppet requirement.
- `spec/classes/`, `spec/defines/`, `spec/unit/facter/` — rspec-puppet and
  fact unit tests. `spec/lib/rendered_config.rb` renders the
  `00_simp_pre_logging` files a catalogue would write.
- `spec/acceptance/suites/{default,doubleforward}/` — beaker acceptance
  suites (the failover specs live in the `default` suite as `04_*`/`05_*`);
  shared multi-host nodesets under `spec/acceptance/nodesets/`.
- There is **no** `data/` or `hiera.yaml` in this module — it ships no
  module-level Hiera data.

## Continuous integration

`.github/workflows/pr_tests.yml` runs `puppet-syntax`, `puppet-style`,
`ruby-style`, `file-checks`, `reference`, `releng-checks`, `spec-tests`, and
an `acceptance` job. The acceptance job runs the `default` and
`doubleforward` suites (`beaker:suites[<suite>,<node>]`) on an
almalinux 8/9/10 matrix via vagrant-libvirt.

## Common commands

```sh
# Install dependencies
bundle install

# Run all unit tests
bundle exec rake spec

# Run a single spec
bundle exec rspec spec/classes/init_spec.rb

# Puppet lint
bundle exec rake lint

# Ruby lint
bundle exec rake rubocop

# Regenerate REFERENCE.md from puppet-strings docstrings
puppet strings generate --format markdown --out REFERENCE.md

# Run a beaker acceptance suite (both suites also run in CI)
bundle exec rake beaker:suites[default]
bundle exec rake beaker:suites[doubleforward]
```

Relevant gem pins (from `Gemfile`): `puppetlabs_spec_helper ~> 8.0.0`,
`simp-rake-helpers ~> 5.24.0`, `simp-rspec-puppet-facts ~> 4.0.0`,
`simp-beaker-helpers ~> 2.0.0`. Rubocop is pinned to `~> 1.88.0`. The
`Gemfile` installs the **`puppet`** gem only (`gem 'puppet', puppet_version`),
with `puppet_version` defaulting to `['>= 7', '< 9']` — there is no `openvox`
gem. `spec/spec_helper.rb` requires
`puppetlabs_spec_helper/module_spec_helper`.

## Conventions

- Preserve the `@summary` / `@param` puppet-strings docstrings on classes and
  defines — they drive `REFERENCE.md`. Regenerate `REFERENCE.md` after
  changing docs or parameters.
- Keep private classes/defines `assert_private()`'d
  (`install.pp`, `service.pp`, `config.pp`,
  `config/logrotate.pp`, and the `server/*` helpers). Consumers enter
  through `rsyslog` or `rsyslog::server`, never the workers.
- Guard optional integrations (`pki`, `iptables`, `logrotate`)
  with `simplib::assert_optional_dependency` behind a feature check — don't
  hard-`include` optional modules.
- Route SIMP feature toggles through `simplib::lookup('simp_options::*', {
  'default_value' => … })` with an explicit default rather than assuming
  `simp_options` is included.
- Add new rules under the correct `NN_simp_*` numeric prefix so include
  ordering stays deterministic. Every file must be a managed `rsyslog::rule`,
  since sites may enable `purge_rule_dir`.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry
  a **puppetsync** notice — they are baseline-managed and the next sync
  overwrites local edits. Push changes to those files upstream to the
  baseline, not here. Exception: the workflow's `jobs.acceptance` block is
  repo-owned — puppetsync's workflow merge preserves it as-is.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in the manifests.
```
