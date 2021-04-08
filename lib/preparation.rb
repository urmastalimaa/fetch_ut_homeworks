require 'fileutils'

# Prepare homework submission for grading
class Preparation
  def initialize(logger, homework_dir)
    @logger = logger
    @homework_dir = homework_dir
  end

  def prepare!
    Dir.glob("./#{@homework_dir}/**").each do |dir_name|
      if File.directory?(dir_name)
        remove_nested_dir!(dir_name)
        install_deps!(dir_name)
      end
    end
  end

  private

  def install_deps!(dir_name)
    @logger.info "Installing dependencies in #{dir_name}"
    Dir.chdir(dir_name) do
      `yarn install`
    end
  end

  def remove_nested_dir!(dir_name)
    dir_names = Dir.glob("#{dir_name}/**").select { |f| File.directory?(f) }
      .reject { |d| File.basename(d).start_with?('_') } # ignore "hidden" folders
    return unless dir_names.length == 1

    @logger.info "Removing nested dir in #{dir_name}"

    nested_dir = dir_names.first
    Dir.glob("#{nested_dir}/**").each { |f| FileUtils.mv(f, dir_name) }
    Dir.glob("#{nested_dir}/.[^.]*").each { |f| FileUtils.mv(f, dir_name) }
    `rmdir '#{nested_dir}'`
  end
end
