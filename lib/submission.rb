# Describes a single submission
class Submission
  attr_reader :remote_path, :matricle_nr, :filename

  def self.from_href(href)
    matricle_nr = href.match(/.*\/get\/\d\/([^._]*).*\//)[1]
    original_filename = href.match(/[^\/]*$/)[0]
    new(href, matricle_nr, original_filename)
  end

  def initialize(remote_path, matricle_nr, filename)
    @remote_path = remote_path
    @matricle_nr = matricle_nr
    @filename = filename
  end
end

# Describes all submissions of a student
class StudentSubmissions
  attr_reader :submission_count, :matricle_nr, :latest

  def initialize(submissions)
    @submissions = submissions
    @matricle_nr = submissions.first.matricle_nr
    @submission_count = submissions.length
    @latest = @submissions.max_by(&:filename)
  end

  def to_s
    "Student #{matricle_nr} submission: " \
      "count: #{submission_count}, " \
      "latest filename: #{latest.filename}"
  end
end
