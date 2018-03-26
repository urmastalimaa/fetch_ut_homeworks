require 'logger'
require 'fetcher'
require 'collector'
require 'preparation'

# Fetches and prepares homework for grading
class Operation
  attr_reader :logger, :homework_nr, :fetcher, :collector, :preparation

  def initialize(course_nr, homework_nr, session_id)
    @homework_nr = homework_nr
    @logger = Logger.new(STDOUT)

    target_dir = "Homework#{homework_nr}"
    @fetcher = Fetcher.new(@logger, course_nr, homework_nr, session_id)
    @collector = Collector.new(@logger, @fetcher, target_dir)
    @preparation = Preparation.new(@logger, target_dir)
  end

  def call
    logger.info "Preparing homework #{homework_nr}"

    fetcher.submissions!.each(&collector.method(:save_submission_to_disk))
    preparation.prepare!
  end
end
