# Downloads a single submissions to disk
class Collector
  def initialize(logger, fetcher, target_dir)
    @logger = logger
    @fetcher = fetcher
    @target_dir = target_dir
  end

  def save_submission_to_disk(student_submission)
    `mkdir -p ./#{@target_dir}/`
    @logger.info "Fetching #{student_submission}"
    binary = @fetcher.download_submission!(student_submission.latest.remote_path)
    write_submission(student_submission, binary)
  end

  private

  def write_submission(student_submission, binary)
    @logger.info "Writing #{student_submission}"
    filename = student_submission.latest.filename
    matricle_nr = student_submission.matricle_nr
    File.open("./#{@target_dir}/#{filename}", 'wb') { |f| f.write(binary) }
    @logger.debug "Unpacking #{student_submission}"
    unpack("./#{@target_dir}/#{filename}", "./#{@target_dir}/#{matricle_nr}")
    `rm ./#{@target_dir}/#{filename}`
    @logger.debug "Adding meta files #{student_submission}"
    add_meta_files(student_submission)
  end

  def add_meta_files(student_submission)
    matricle_nr = student_submission.matricle_nr
    File.open("./#{@target_dir}/#{matricle_nr}/original_filename.meta", 'wb') do |f|
      f.write(student_submission.latest.filename)
    end
    File.open("./#{@target_dir}/#{matricle_nr}/submission_count.meta", 'wb') do |f|
      f.write(student_submission.submission_count)
    end
    File.open("./#{@target_dir}/#{matricle_nr}/matricle_nr.meta", 'wb') do |f|
      f.write(student_submission.matricle_nr)
    end
  end

  def unpack(filename, target_dir)
    `/Applications/Keka.app/Contents/Resources/keka7z x -y -o./#{target_dir} #{filename}`
  end
end
