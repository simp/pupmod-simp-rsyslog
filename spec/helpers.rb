module Helpers
  attr_accessor :hieradata_dirs

  def clear_temp_hieradata
    if @hieradata_dirs && !@hieradata_dirs.empty?
      @hieradata_dirs.each do |data_dir|
        FileUtils.rm_r(data_dir)
      end
    end
  end

  def set_hieradata_on(target_system, hieradata, data_file='default', hiera_config=nil)
    @hieradata_dirs ||= @hieradata_dirs = []

    data_dir = Dir.mktmpdir('hieradata')
    @hieradata_dirs << data_dir

    hiera_config = Array(data_file) unless hiera_config

    fh = File.open(File.join(data_dir,"#{data_file}.yaml"),'w')
    fh.puts(hieradata.to_yaml)
    fh.close

    # Copy to has a bug where it doesn't account for directory copies properly
    # so we need to clear out the space on the system prior to the copy.
    apply_manifest_on(
      target_system,
      "file { '#{target_system[:hieradatadir]}': ensure => 'absent', force => true, recurse => true }"
    )
    copy_hiera_data_to(target_system, data_dir)
    write_hiera_config_on(target_system, hiera_config)
  end
end
