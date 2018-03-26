require 'faraday'
require 'nokogiri'
require 'submission'

# Fetches information about all submissions for a single task from the course page
class Fetcher
  DOMAIN = 'https://courses.cs.ut.ee'.freeze

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
    request_from_courses(path).body
  end

  private

  def request_from_courses(path)
    @conn.get do |req|
      req.url path
      req.headers['Cookie'] = "COURSESSID=#{@session_id}"
    end
  end

  def submissions_html
    Nokogiri::HTML(request_from_courses(@remote_path).body)
  end

  def extract_submission_hrefs(html)
    html
      .css('tbody > tr')
      .map { |r| r.css('a').first }
      .compact
      .map { |href| href.attributes['href'].value }
  end
end
