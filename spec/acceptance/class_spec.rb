require 'spec_helper_acceptance'

test_name 'rsyslog class'

describe 'rsyslog class' do
  package_name = 'rsyslog'
  if fact('osfamily') == 'RedHat' && fact('operatingsystemmajrelease') == '6'
    package_name = 'rsyslog7'
  end

  let(:manifest) {
    <<-EOS
      class { 'rsyslog': manage_pki_certs  => false }
    EOS
  }

  context 'default parameters (no pki)' do

    # Using puppet_apply as a helper
    it 'should work with no errors' do
      apply_manifest(manifest, :catch_failures => true)

      # reboot to apply auditd changes
      # shell( 'shutdown -r now', { :expect_connection_failure => true } )
    end


    it 'should be idempotent' do
      apply_manifest(manifest, {:catch_changes => true})
    end

    describe package(package_name) do
      it { is_expected.to be_installed }
    end

    describe service('rsyslog') do
      it { is_expected.to be_enabled }
      it { is_expected.to be_running }
    end
  end
end
