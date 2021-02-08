require 'spec_helper'

describe 'custom fact rsyslogd' do
  before(:each) do
    Facter.clear

    expect(Facter::Core::Execution).to receive(:which).with('rsyslogd').and_return('/usr/sbin/rsyslogd')
  end

  context 'with version info in expected format' do
    let (:rsyslogd_info) { <<~EOM
        rsyslogd  8.1911.0-6.el8 (aka 2019.11) compiled with:
        \tPLATFORM:\t\t\t\tx86_64-redhat-linux-gnu
        \tPLATFORM (lsb_release -d):\t\t
        \tFEATURE_REGEXP:\t\t\t\tYes
        \tGSSAPI Kerberos 5 support:\t\tYes
        \tFEATURE_DEBUG (debug build, slow code):\tNo
        \t32bit Atomic operations supported:\tYes
        \t64bit Atomic operations supported:\tYes
        \tmemory allocator:\t\t\tsystem default
        \tRuntime Instrumentation (slow code):\tNo
        \tuuid support:\t\t\t\tYes
        \tsystemd support:\t\t\tYes
        \tConfig file:\t\t\t\t/etc/rsyslog.conf
        \tPID file:\t\t\t\t/var/run/rsyslogd.pid
        \tNumber of Bits in RainerScript integers: 64

        See https://www.rsyslog.com for more information.
      EOM
    }

    let (:expected_fact) {{
      'version'                                 => '8.1911.0',
      'features'                                => {
        'PLATFORM'                                => 'x86_64-redhat-linux-gnu',
       # 'PLATFORM (lsb_release -d)' is omitted because it does not have a value
        'FEATURE_REGEXP'                          => true,
        'GSSAPI Kerberos 5 support'               => true,
        'FEATURE_DEBUG (debug build, slow code)'  => false,
        '32bit Atomic operations supported'       => true,
        '64bit Atomic operations supported'       => true,
        'memory allocator'                        => 'system default',
        'Runtime Instrumentation (slow code)'     => false,
        'uuid support'                            => true,
        'systemd support'                         => true,
        'Config file'                             => '/etc/rsyslog.conf',
        'PID file'                                => '/var/run/rsyslogd.pid',
        'Number of Bits in RainerScript integers' =>  64
      }
    }}

    it 'should return hash with populated version and features' do
      expect(Facter::Core::Execution).to receive(:exec).with('/usr/sbin/rsyslogd -v').and_return(rsyslogd_info)
      expect(Facter.fact('rsyslogd').value).to eq(expected_fact)
    end
  end

  context 'with version info in unexpected format' do
    # non-standard version line ('rsyslogd version x.y.z' instead of
    # 'rsyslogd x.y.z') and non-standard feature lines ('=' separator instead
    # of ':" separator)
    let (:rsyslogd_info) { <<~EOM
        rsyslogd version 8.1911.0-6.el8 (aka 2019.11) compiled with:
          PLATFORM = x86_64-redhat-linux-gnu
          PLATFORM (lsb_release -d) =
          FEATURE_REGEXP = Yes
          GSSAPI Kerberos 5 support = Yes
          FEATURE_DEBUG (debug build, slow code) = No
          32bit Atomic operations supported = Yes
          64bit Atomic operations supported = Yes
          memory allocator = system default
          Runtime Instrumentation (slow code) = No
          uuid support = Yes
          systemd support = Yes
          Config file = /etc/rsyslog.conf
          PID file = /var/run/rsyslogd.pid
          Number of Bits in RainerScript integers =  64

        See https://www.rsyslog.com for more information.
      EOM
    }

    let (:expected_fact) { { 'version' => nil, 'features' => {} } }

    it 'should return hash with nil version and empty features' do
      expect(Facter::Core::Execution).to receive(:exec).with('/usr/sbin/rsyslogd -v').and_return(rsyslogd_info)
      expect(Facter.fact('rsyslogd').value).to eq(expected_fact)
    end
  end
end
