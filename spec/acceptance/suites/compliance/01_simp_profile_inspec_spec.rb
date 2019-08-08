require 'spec_helper_acceptance'
require 'json'

test_name 'Check Inspec for simp profile'

describe 'run inspec against the appropriate fixtures for simp rsyslog profile' do

  profiles_to_validate = ['disa_stig']

  hosts.each do |host|
    profiles_to_validate.each do |profile|
      context "for profile #{profile}" do
        context "on #{host}" do
          profile_path = File.join(
                fixtures_path,
                'inspec_profiles',
                "#{fact_on(host, 'operatingsystem')}-#{fact_on(host, 'operatingsystemmajrelease')}-#{profile}"
              )

          unless File.exist?(profile_path)
            it 'should run inspec' do
              skip("No matching profile available at #{profile_path}")
            end
          else
            before(:all) do
              @inspec = Simp::BeakerHelpers::Inspec.new(host, profile)
              @inspec_report = {:data => nil}
            end

            it 'should run inspec' do
              @inspec.run
            end

            it 'should have an inspec report' do
              @inspec_report[:data] = @inspec.process_inspec_results

              info = [
                'Results:',
                "  * Passed: #{@inspec_report[:data][:passed]}",
                "  * Failed: #{@inspec_report[:data][:failed]}",
                "  * Skipped: #{@inspec_report[:data][:skipped]}"
              ]

              puts info.join("\n")

              @inspec.write_report(@inspec_report[:data])
            end

            it 'should have run some tests' do
              expect(@inspec_report[:data][:failed] + @inspec_report[:data][:passed]).to be > 0
            end

            it 'should not have any failing tests' do
              # 2 tests erroneously fail
              # - 'All privileged function executions must be audited':
              #    - inspec_profiles/profiles/disa_stig-el7-baseline/controls/V-72095.rb
              #    - inspec is expecting watches for executables.  We are checking with
              #      syscalls instead
              # - 'The system must send rsyslog output to a log aggregation server':
              #    - inspec_profiles/profiles/disa_stig-el7-baseline/controls/V-72209.rb
              #    - inspec should skip, as rsyslog is not setup

              if @inspec_report[:data][:failed] > 0
                puts @inspec_report[:data][:report]
              end

              expect( @inspec_report[:data][:failed] ).to eq(0)
            end
          end
        end
      end
    end
  end
end