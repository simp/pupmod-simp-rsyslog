require 'spec_helper'

describe 'rsyslog::add_rule' do
  let(:title) {'add_rule_test'}
  let(:params) {{
    :rule => 'test rule'
  }}

  context 'base' do
    it { should create_concat_fragment('rsyslog+add_rule_test.rule').with({
        :content => /test\srule/
      })
    }
  end
end
