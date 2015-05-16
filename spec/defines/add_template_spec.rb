require 'spec_helper'

describe 'rsyslog::add_template' do
  let(:title) {'add_template_test'}
  let(:params) {{
    :content => 'test template'
  }}

  context 'base' do
    it { should create_concat_fragment('rsyslog+add_template_test.template').with({
        :content => /\$template\sadd_template_test,\"test\stemplate\"/
      })
    }
  end
end
