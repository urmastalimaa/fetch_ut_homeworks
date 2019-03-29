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

  def download_submission!(path, retry_budget = 10)
    @logger.info "Downloading submission #{path}"
    html = request_from_courses(path, 'Accept' => 'application/zip').body
    if html.match?('DOCTYPE html')
      if retry_budget > 0
        download_submission!(path, retry_budget - 1)
      else
        raise CouldNotDownloadSubmission
      end
    else
      html
    end
  end

  private

  def request_from_courses(path, headers = {})
    @conn.get do |req|
      req.url path
      req.headers['Cookie'] = "COURSESSID=#{@session_id}"
      headers.each { |k, v| req.headers[k] = v }
    end
  end

  def submissions_html
    Nokogiri::HTML(request_from_courses(@remote_path).body).tap do |html|
      raise BadRequest, 'Ensure that your session ID is valid and that you are logged in' if html.at(BAD_REQUEST_MARKER)
    end
  end

  def extract_submission_hrefs(html)
    html
      .css('tbody > tr')
      .map { |r| r.css('a').first }
      .compact
      .map { |href| href.attributes['href'].value }
  end
end
