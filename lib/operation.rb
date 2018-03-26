require './fetcher'
require './collector'
require './preparation'

# Fetches and prepares homework for grading
class Operation
  def initialize(homework_nr, session_id)
    target_dir = "Homework#{homework_nr}"
    @fetcher = Fetcher.new(homework_nr, session_id)
    @collector = Collector.new(fetcher, target_dir)
    @preparation = Preparation.new(target_dir)
  end

  def call
    @fetcher.submissions!.each(@collector.method(&:save_submission_to_disk))
    @preparation.prepare!
  end
end
