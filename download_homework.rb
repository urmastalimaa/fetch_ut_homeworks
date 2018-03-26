$LOAD_PATH << File.dirname(__FILE__) + '/lib'

require 'optparse'
require 'operation'

options = {}
OptionParser.new do |opts|
  opts.banner = 'Usage: download_homework.rb [options]'

  opts.on('-n', '--homework_nr HOMEWORK_NR', 'Homework nr') do |n|
    options[:homework_nr] = n
  end

  opts.on('-s', '--session_id SESSION_ID', 'Login session id') do |id|
    options[:session_id] = id
  end

  opts.on('-h', '--help', 'Prints this help') do
    puts opts
    exit
  end
end.parse!

Operation.new(options.fetch(:homework_nr), options.fetch(:session_id)).call
