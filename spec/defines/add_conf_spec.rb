require 'spec_helper'

describe 'rsyslog::add_conf' do
  let(:title) {'add_conf_test'}
  let(:params) {{
    :content => 'test content'
  }}

  context 'base' do
    it { should create_file('/etc/rsyslog.d/puppet_managed/add_conf_test.conf').with({
        :content => /test\scontent/,
        :notify  => 'Service[rsyslog]'
      })
    }
  end
end
