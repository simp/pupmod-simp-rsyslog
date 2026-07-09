# AGENTS.md

This file provides guidance to AI agents when working with code in this repository.

## What this module does

`simp-rsyslog` is a SIMP Puppet module that installs, configures, and manages
**Rsyslog version 8** on Enterprise Linux systems. It writes a minimal
`/etc/rsyslog.conf` that does nothing but `$IncludeConfig` a SIMP-owned drop-in
directory (`/etc/rsyslog.simp.d`), then populates that directory with numbered
`.conf` fragments so that rule ordering is deterministic. On top of the base
client configuration it layers a server role (listeners for TCP, TLS-TCP, and
UDP), TLS/PKI for encrypted log transport, optional `logrotate`, and — for a
server — optional `iptables`, SELinux, and TCPWrappers integration.

The configuration is deliberately slanted toward the quirks of the Rsyslog
builds shipped with Enterprise Linux (`manifests/init.pp:1-6`). It targets
Rsyslog 8-stable and emits a runtime `warning` if the installed `rsyslogd` is
older than `8.24.0`, pointing the operator at module version `7.6.4` instead
(`manifests/init.pp:151-153`). The installed version is discovered by a custom
fact (`lib/facter/rsyslogd.rb`) that parses `rsyslogd -v`.

Everything is driven through a rich set of defined types: rules
(`rsyslog::rule` and its typed wrappers) and templates
(`rsyslog::template::*`). Rules are dropped into numbered subdirectories of
`$rule_dir` so their evaluation order is fixed, and the whole directory is
managed with `purge => true` — anything not managed by Puppet is removed.

## Business logic

### Class graph

The public entry class is `rsyslog` (`manifests/init.pp`). It `contain`s the
three private worker classes and pins their ordering
(`manifests/init.pp:155-163`):

```
Class['rsyslog::install'] -> Class['rsyslog::config'] ~> Class['rsyslog::service']
```

- **`rsyslog` (`manifests/init.pp:127-175`)** — Public class; consumers
  `include 'rsyslog'`. Holds the client-facing parameters: package/service
  names, `trusted_nets`, `log_servers` / `failover_log_servers`, the listener
  toggles (`tcp_server`, `tls_tcp_server`, `udp_server`) and their ports,
  `enable_tls_logging`, `pki`, `logrotate`, and a `rules` hash. When
  `$logrotate` is true it additionally `contain`s
  `rsyslog::config::logrotate` after the service
  (`manifests/init.pp:165-168`). It iterates `$rules` and declares a
  `rsyslog::rule` per entry via the splat operator
  (`manifests/init.pp:170-174`), which is how rules can be created purely from
  Hiera.
- **`rsyslog::install` (`manifests/install.pp`)** — `assert_private()`
  (`install.pp:14`). Installs the core package and, where relevant, the TLS
  (`rsyslog-gnutls`) package; handles i386-on-x86_64 package removal.
- **`rsyslog::config` (`manifests/config.pp`)** — `assert_private()`
  (`config.pp:429`). The heart of the module. Writes `/etc/rsyslog.conf`,
  `/etc/sysconfig/rsyslog`, the managed rule directory, and the base rule
  fragments (`00_simp_pre_logging/global.conf` from
  `templates/config/pre_logging.conf.epp`, a `09_failover_hack` no-op rule
  needed so failover parses, and — when `enable_default_rules` — a
  `99_simp_local/ZZ_default.conf`). It carries the bulk of the tunable
  parameters (imuxsock `SysSock.*`, main-message-queue sizing, TLS stream
  driver settings, `imtcp` keep-alive, DNS/ACL behavior). It also handles the
  PKI branch and an EL7-specific systemd override (see Gotchas).
- **`rsyslog::service` (`manifests/service.pp`)** — `assert_private()`
  (`service.pp:11`). Manages the `rsyslog` service state.
- **`rsyslog::config::logrotate` (`manifests/config/logrotate.pp`)** —
  `assert_private()` (`config/logrotate.pp:88`); asserts the optional
  `simp/logrotate` dependency (`config/logrotate.pp:90`) and proxies its
  parameters to a `logrotate::rule` for the syslog logs.

### Server role

`rsyslog::server` (`manifests/server.pp:16-40`) is the entry point for a host
that must **receive** logs. It `include`s `rsyslog` and then conditionally
`contain`s three private helpers based on `simp_options` toggles:

- **`rsyslog::server::firewall`** — `assert_private()`; asserts the optional
  `simp/iptables` dependency (`manifests/server/firewall.pp`). Opens the
  enabled listener ports (TLS-TCP, TCP, UDP) to `$rsyslog::trusted_nets`.
  Enabled by `simp_options::firewall`.
- **`rsyslog::server::selinux`** — `assert_private()`
  (`manifests/server/selinux.pp`). Sets the `nis_enabled` SELinux boolean when
  SELinux is enforcing. Enabled by default from the
  `os.selinux.enforced` fact (`server.pp:18`); ordered **before** the service.
- **`rsyslog::server::tcpwrappers`** — `assert_private()`; asserts the optional
  `simp/tcpwrappers` dependency (`manifests/server/tcpwrappers.pp`). Opens the
  `syslog` / `syslog_tls` services. Enabled by `simp_options::tcpwrappers`.

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
  queue-parameter validation, renders `templates/rule/remote.epp`)
- `rsyslog::rule::other` → `20_simp_other` (arbitrary, unstructured rules)
- `rsyslog::rule::remote` → `10_simp_remote` (forward to remote servers; TLS,
  compression, disk-assisted queues, IP-vs-hostname peer handling)

Templates map to the four Rsyslog template kinds, each written under
`05_simp_templates`: `rsyslog::template::list`, `::plugin`, `::string`, and
`::subtree`.

## Gotchas / non-obvious details

- **The managed rule directory is purged.** `$rule_dir`
  (`/etc/rsyslog.simp.d`) is declared with `recurse => true, purge => true,
  force => true` (`config.pp:488-496`). Any `.conf` not managed by a
  `rsyslog::rule` (directly or via the `rules` Hiera hash) will be deleted on
  the next run. To ship files that SIMP should *not* manage, set
  `rsyslog::config::include_rsyslog_d: true` and drop them in
  `/etc/rsyslog.d` (see the generated `README_SIMP.conf`,
  `config.pp:505-517`, `config.pp:574-578`).
- **Rule ordering is encoded in directory-number prefixes.** The `NN_simp_*`
  prefixes (`00_simp_pre_logging`, `05_*`, `06_*`, `07_*`, `09_failover_hack`,
  `10_simp_remote`, `20_simp_other`, `99_simp_local`) exist so `$IncludeConfig
  *.conf` evaluates them in the intended order. Preserve these prefixes when
  adding rule types.
- **The `09_failover_hack` rule is load-bearing.** Rsyslog will not parse a
  failover action definition unless at least one rule already exists, so the
  module emits a no-op `continue` rule first (`config.pp:563-572`). Don't
  remove it.
- **EL7 (`rsyslogd` 8.24.0) gets a systemd drop-in.** When the installed
  version is exactly `8.24.0`, `rsyslog::config` writes a
  `systemd::dropin_file` adding `network.target`/`network-online.target` to
  the unit's `Wants`/`After` to fix a service-ordering bug in
  `rsyslog-8.24.0-12.el7` (`config.pp:587-606`). It is harmless on builds that
  already have the fix because the lists are de-duplicated.
- **Versions older than 8.24.0 are unsupported.** `rsyslog::init` warns and
  points at module `7.6.4` (`init.pp:151-153`). This gate depends on the
  custom `rsyslogd` fact (`lib/facter/rsyslogd.rb`) being present.
- **TLS is inferred, not just toggled.** `imtcp_stream_driver_mode` is derived:
  it is `'1'` when any of `$rsyslog::pki`, `$rsyslog::tls_tcp_server`, or
  `$rsyslog::enable_tls_logging` is set, else `'0'` (`config.pp:403`); the
  auth mode then defaults from that (`anon` vs `x509/name`,
  `config.pp:468-476`). The CA/cert/key paths default under `$app_pki_dir`
  (`/etc/pki/simp_apps/rsyslog/x509`) and are the **only** way to set the TLS
  material (`config.pp:398-400`).
- **PKI is gated behind an optional dependency.** `rsyslog::config` only pulls
  in PKI when `$rsyslog::pki` is truthy, and asserts `simp/pki` at runtime
  before calling `pki::copy` (`config.pp:459-466`). `pki` accepts `'simp'`,
  `true`, or `false` with distinct meanings (see the `@param pki` docs in
  `init.pp:92-104`).
- **Several parameters are deprecated but still wired.** `rsyslog::config`
  emits `warning`s for `default_template`, `action_send_stream_driver_mode`,
  `action_send_stream_driver_auth_mode`, `suppress_noauth_warn`, and
  `disable_remote_dns`, each pointing at its replacement
  (`config.pp:431-449`). Prefer the replacements
  (`default_file_template`, `imtcp_stream_driver_*`, `net_permit_acl_warning`,
  `net_enable_dns`).
- **Queue sizing is fact-derived math.** The main-message-queue size and its
  high/low/discard watermarks and worker-thread counts are computed from
  `memory.system.total_bytes` and `processors.count`
  (`config.pp:378-383`); the per-rule `local`/`remote` defines re-validate
  supplied queue parameters against each other.
- **`simp/simp_options` is NOT a declared dependency** in `metadata.json`, yet
  the manifests consume the `simp_options::*` seam via `simplib::lookup`
  (provided by `simp/simplib`). `simp_options` appears only as a fixture
  (`.fixtures.yml`).

## The `simp_options` / `simplib::lookup` seam

This is the module's real business-logic seam — the SIMP-wide feature toggles
that let one Hiera setting drive many modules. All calls pass an explicit
`default_value` so the module works even when `simp_options` is not included:

| Location | Key | `default_value` |
|----------|-----|-----------------|
| `init.pp:132` | `simp_options::trusted_nets` | `['127.0.0.1/32']` |
| `init.pp:134` | `simp_options::syslog::log_servers` | `[]` |
| `init.pp:135` | `simp_options::syslog::failover_log_servers` | `[]` |
| `init.pp:145` | `simp_options::logrotate` | `false` |
| `init.pp:146` | `simp_options::pki` | `false` |
| `init.pp:147` | `simp_options::pki::source` | `'/etc/pki/simp/x509'` |
| `server.pp:17` | `simp_options::firewall` | `false` |
| `server.pp:19` | `simp_options::tcpwrappers` | `false` |

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

- `simp/pki` `>= 6.2.0 < 7.0.0` — asserted at `manifests/config.pp:460` when
  `$rsyslog::pki`.
- `simp/tcpwrappers` `>= 6.2.0 < 7.0.0` — asserted in
  `manifests/server/tcpwrappers.pp`.
- `simp/logrotate` `>= 6.5.0 < 7.0.0` — asserted at
  `manifests/config/logrotate.pp:90`.
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
- `manifests/server/{firewall,selinux,tcpwrappers}.pp` — private server-role
  helpers.
- `manifests/rule.pp` + `manifests/rule/{console,data_source,drop,local,other,remote}.pp`
  — the rule defined types.
- `manifests/template/{list,plugin,string,subtree}.pp` — the template defined
  types.
- `types/boolean.pp` — `Rsyslog::Boolean = Variant[Enum['on','off'],Boolean]`.
- `types/options.pp` — `Rsyslog::Options = Hash[String,Variant[Numeric,String]]`.
- `types/queuetype.pp` — `Rsyslog::QueueType =
  Enum['FixedArray','LinkedList','Direct','Disk']`.
- `templates/config/pre_logging.conf.epp` — the global pre-logging fragment.
- `templates/rule/local.epp`, `templates/rule/remote.epp` — rule bodies.
- `lib/facter/rsyslogd.rb` — custom fact parsing `rsyslogd -v` into
  `{ version, features }`; drives the version gate in `init.pp`.
- `metadata.json` — deps, optional deps, OS matrix, Puppet requirement.
- `spec/classes/`, `spec/defines/`, `spec/unit/facter/` — rspec-puppet and
  fact unit tests.
- `spec/acceptance/suites/{default,doubleforward,failover}/` — beaker
  acceptance suites; nodesets under `spec/acceptance/nodesets/`
  (`centos-7.yml`, `default.yml`, `oel.yml`).
- There is **no** `data/` or `hiera.yaml` in this module — it ships no
  module-level Hiera data.

## Continuous integration

`.github/workflows/pr_tests.yml` runs **six** jobs and no more:
`puppet-syntax`, `puppet-style`, `ruby-style`, `file-checks`,
`releng-checks`, and `spec-tests`. **There is no acceptance job in CI** — no
beaker, no nodesets, and no `BEAKER_HYPERVISOR` in the workflow. The
acceptance suites and nodesets ship in the repo but are **local-only**; run
them by hand with beaker (see Common commands).

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

# Run a beaker acceptance suite (LOCAL ONLY — not run in CI)
bundle exec rake beaker:suites[default]
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
  (`install.pp:14`, `service.pp:11`, `config.pp:429`,
  `config/logrotate.pp:88`, and the `server/*` helpers). Consumers enter
  through `rsyslog` or `rsyslog::server`, never the workers.
- Guard optional integrations (`pki`, `iptables`, `logrotate`, `tcpwrappers`)
  with `simplib::assert_optional_dependency` behind a feature check — don't
  hard-`include` optional modules.
- Route SIMP feature toggles through `simplib::lookup('simp_options::*', {
  'default_value' => … })` with an explicit default rather than assuming
  `simp_options` is included.
- Add new rules under the correct `NN_simp_*` numeric prefix so include
  ordering stays deterministic; the rule directory is purged, so every file
  must be a managed `rsyslog::rule`.
- `Gemfile`, `spec/spec_helper.rb`, and `.github/workflows/pr_tests.yml` carry
  a **puppetsync** notice — they are baseline-managed and the next sync
  overwrites local edits. Push changes to those files upstream to the
  baseline, not here.
- Match the existing 2-space Puppet indentation and aligned-arrow parameter
  style used in the manifests.
```
