# Utility plugin for running tasks via cron
#
# To use: create an executable ruby script in a bin directory under the
# rails directory that contains something like
#
#   #! /usr/local/bin/ruby
#   require File.dirname(__FILE__) + '/../vendor/plugins/job_runner/lib/job_runner.rb'
#   JobRunner::offer(:push, :do)
#
# Then populate lib/job_runner/push.rb and lib/job_runner/do.rb


module JobRunner

  #----------
  #
  # Proxy class to allow the LOGGER constant to return something that
  # acts like a logger but has a changeable logger within and also
  # maintains a seperate log record for JobStatus tracking
  #
  #----------

  class LoggerProxy

    @@local_log_io = StringIO.new()
    @@local_log = Logger.new(@@local_log_io)

    def self.local_log
      @@local_log_io.string
    end

    # This is a bit of a hack.
    #
    # Required because the ebay and google_products code uses a
    # pluggable logger (either "puts" or this) and when we plug in
    # this as a logger (see function ebay_post() in file
    # lib/tvr/do.rb) we want to know what specific method we're going
    # to call on the global logger object and the method_missing
    # approach just up above fails when we call method(:info)...
    def info(*args)
      JobRunner.current_logger.info(*args)

      @@local_log.info(*args)
    end

    def method_missing(*args)
      JobRunner.current_logger.send(*args)
      @@local_log.send(*args)
    end


    
  end

  LOGGER = JobRunner::LoggerProxy.new


  #----------
  # Now on to JobRunner proper
  #----------

  # Offer a rails based environment for running jobs via an executable script
  def JobRunner::offer(task_name)

    JobRunner::setup_logger(task_name)
    
    success = false
    
    JobStatus::track_start(task_name)  

    begin
      start_time = Time.now

      LOGGER.info "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
      LOGGER.info "TASK:  #{task_name}"
      LOGGER.info "ENV:   #{Rails.env}"
      LOGGER.info "ENV:   #{ENV.inspect}"
      LOGGER.info "HOST:  #{ENV["HOST"] || `uname -n`.strip}"
      LOGGER.info "USER:  #{ENV["USERNAME"]}"
      LOGGER.info "START: #{start_time}"
      LOGGER.info "PID:   #{$$}"
      LOGGER.info "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

      JobRunner::Do.send(task_name)

      elapsed_time = Time.now - start_time
      elapsed = case elapsed_time
                when 0...60 then "#{elapsed_time.to_i} second#{elapsed_time.to_i != 1 ? 's' : ''}"
                else "#{'%0.1f' % (elapsed_time / 60)} minute#{('%0.1f' % (elapsed_time / 60)) != '1.0' ? 's' : ''}"
                end
      LOGGER.info ""
      LOGGER.info "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="
      LOGGER.info "Elapsed time: #{elapsed}"
      LOGGER.info "=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-="

      JobStatus::track_success(LoggerProxy.local_log) 
    rescue => e
      puts "***** Error: #{e}"
      LOGGER.info("***** Error: #{e}")

      puts "***** #{e.backtrace.join("\n")}"
      LOGGER.info(e.backtrace.join("\n"))

      JobStatus::track_failure(LoggerProxy.local_log) 
      usage
      return false
    end

    true
  end

  # Set up a usage message
  def JobRunner::usage
    puts "\n"
    puts "Usage: EMAIL_PREFIX=sf LOG_EMAIL=xyz@smartflix rails runner -e production <task>"
  end

  #----------
  # logger
  #----------

  @@current_logger = ::Logger.new(STDOUT)

  # Utility methods to get and set the current logger
  def JobRunner.current_logger
    @@current_logger
  end

  def JobRunner.current_logger=(new_logger)
    @@current_logger = new_logger
  end

  def JobRunner.setup_logger(task_name)
    email_to    = ENV['LOG_EMAIL']
    email_prefix = ENV['EMAIL_PREFIX'] || ''
    email_subject = "[#{email_prefix}] JOB: #{task_name}"
    @@current_logger = ENV['LOG_EMAIL'] ? EmailLogger.new(email_to, email_subject) : Logger.new(STDOUT)
    @@current_logger.level = Logger::DEBUG
  end


  # Utility method that allows the logger to be temporarily changed within a block
  def JobRunner.temp_logger(temp_logger)
    saved_logger, @@current_logger = @@current_logger, temp_logger
    yield
    @@current_logger = saved_logger
  end

  # Utility method that captures and returns the results that have been
  # logged during the block (in addition to logging them!)
  def JobRunner.capture_log(&block)
    output_buffer = StringIO.new()
    logger = Logger.new(output_buffer)
    logger.level = JobRunner::LOGGER.level
    JobRunner.temp_logger(logger, &block)
    JobRunner::LOGGER << output_buffer.string
    return output_buffer.string
  end


end

