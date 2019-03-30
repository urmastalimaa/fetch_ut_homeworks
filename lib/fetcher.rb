require 'faraday'
require 'nokogiri'
require 'submission'

# Fetches information about all submissions for a single task from the course page
class Fetcher
  DOMAIN = 'https://courses.cs.ut.ee'.freeze
  BAD_REQUEST_MARKER = "h1:contains('Päring oli väga paha')".freeze

  BadRequest = Class.new(StandardError)
  CouldNotDownloadSubmission = Class.new(StandardError)

  def initialize(logger, course_nr, homework_nr, session_id)
    @logger = logger
    @homework_nr = homework_nr
    @course_nr = course_nr
    @session_id = session_id
    @remote_path = "/course-#{course_nr}/submissions/by_task/#{homework_nr}"

    @conn = Faraday.new(url: DOMAIN) do |faraday|
      faraday.adapter Faraday.default_adapter # make requests with Net::HTTP
    end
  end

  def submissions!
    @logger.info "Fetching submission info for homework #{@homework_nr} for course #{@course_nr}"
    extract_submission_hrefs(submissions_html)
      .map(&Submission.method(:from_href))
      .group_by(&:matricle_nr)
      .map { |_, submissions| StudentSubmissions.new(submissions) }
  end

  def download_submission!(path)
    @logger.info "Downloading submission #{path}"
    retry_with_check(-> { fetch_submission_contents(path) }, 10) do |result|
      raise CouldNotDownloadSubmission if result.match?('DOCTYPE html')
    end
  end

  private

  def fetch_submission_contents(path)
    request_from_courses(path, 'Accept' => 'application/zip').body
  end

  def retry_with_check(operation, budget, &check)
    result = operation.call
    yield result
    result
  rescue StandardError
    return retry_with_check(operation, budget - 1, &check) if budget > 0

    raise
  end

  def request_from_courses(path, headers = {})
    @conn.get do |req|
      req.url path
      req.headers['Cookie'] = "COURSESSID=#{@session_id}"
      headers.each { |k, v| req.headers[k] = v }
    end
  end

  def submissions_html
    retry_with_check(-> { Nokogiri::HTML(request_from_courses(@remote_path).body) }, 10) do |html|
      raise BadRequest, 'Ensure that your session ID is valid and that you are logged in' if html.at(BAD_REQUEST_MARKER)
    end
  end

  def extract_submission_hrefs(html)
    html
      .css('tbody > tr')
      .map { |r| r.css("a[href*='submissions']").first }
      .compact
      .map { |href| href.attributes['href'].value }
  end
end
