# Utility class for searching
#
# status as of Jan 2013:
#   * we've replaced ferret with sphinx
#   * build sphinx index
#         rake ts:index
#   * start sphinx with
#         rake ts:start
#

class Searcher

  # Rebuild Indexes.
  #
  # Files are in 
  #    db/sphinx/development
  #
  def self.rebuild_indexes(logger)

    # cron will run this from someplace weird;
    # make sure to 'cd' to correct location first
    #
    # had a weird situation: rake task was working for me from the command line, but not from 
    # inside job_runner -> Searcher.rb -> this line of code
    # Difference?  PATH variable.
    #
    # NOT NECESSARY in new rails 3 world
    # ENV["PATH"] = "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"

    command = "cd #{Rails.root.to_s} ; rake ts:rebuild RAILS_ENV=#{Rails.env} 2>&1"

    logger.info "* env = #{ENV.inspect}"
    logger.info "* command = #{command}"
    
    `#{command}`
  end


end
