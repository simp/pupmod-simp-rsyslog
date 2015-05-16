require 'spec_helper'

describe 'rsyslog' do
  let(:facts) {{
    :hardwaremodel => 'x86_64'
  }}

  it { should create_class('rsyslog') }

  it { should compile.with_all_deps }
  it { should contain_class('logrotate') }
  it { should contain_package('rsyslog.x86_64') }
  it { should contain_package('rsyslog.i386').with_ensure('absent') }

  it { should create_concat_build('rsyslog').with({
      :target => '/etc/rsyslog.conf'
    })
  }

  it { should create_file('/etc/rsyslog.conf').with({
      :ensure    => 'present',
      :notify    => 'Service[rsyslog]',
      :require   => 'Package[rsyslog.x86_64]',
      :subscribe => 'Concat_build[rsyslog]'
    })
  }

  it { should create_file('/etc/rsyslog.d/puppet_managed').with({
      :ensure  => 'directory',
      :notify  => 'Concat_build[rsyslog]',
      :require => 'Package[rsyslog.x86_64]'
    })
  }

  it { should create_file('/etc/rsyslog.d/README.conf').with({
      :ensure   => 'present',
      :content  => /Place .conf files that rsyslog should process into this directory/,
      :require  => 'Package[rsyslog.x86_64]'
    })
  }

  it { should create_file('/var/spool/rsyslog').with({
      :ensure  => 'directory',
      :require => 'Package[rsyslog.x86_64]'
    })
  }

  it { should contain_service('rsyslog').with({
      :ensure  => 'running',
      :require => ['File[/etc/rsyslog.conf]', 'Package[rsyslog.x86_64]']
    })
  }
end
