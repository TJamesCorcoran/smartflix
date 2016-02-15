# THIS FILE: job_runner/lib/do.rb  <--- BASE

# The class
#     JobRunner::Do
# gets opened and redefined multiple times.
#     * base        lib/job_runner/lib/do.rb
#     * newsletter  lib/newsletter_editor/lib/do.rb
#     * heavyink    lib/job_runner_hi/do.rb

# This provides just a few sample jobs.
# You want to create your own jobs in A DIFFERENT FILE.
#
# e.g. 
#    lib/job_runner_hi/do.rb
# or 
#    lib/job_runner_sf/do.rb

module JobRunner
  class Do
    #----------
    # dummy jobs, for developers to read
    #----------
    
    def self.nothing
      LOGGER.info "nothing"
    end
    
    def self.error 
      raise "error"
    end
    
    
    # path: where to dump to
    #
    def self.db_dump_internal(ignore_tables, path)
      db_config = YAML.load_file("#{Rails.root}/config/database.yml")
      db_config = db_config[Rails.env] if db_config
      unless db_config
        LOGGER.error("Database configuration for environment '#{RAILS_ENV}' does not exist!")
        return 
      end

      # build command line
      #
      options = "--create-options --single-transaction --quick"
      options << " --host #{db_config['host']}" if db_config['host']
      options << " --port #{db_config['port']}" if db_config['port']
      
      date_postfix = Date.today.strftime('%Y_%m_%d')
      outfile = "#{path}#{'/' unless path[-1].chr == '/'}#{db_config['database']}_#{date_postfix}.sql.gz"

      credentials = "--user=#{db_config['username']} #{"--password=#{db_config['password']}" if db_config['password']}"
      ignore_flags = ignore_tables.map { |table| "--ignore_table=#{db_config['database']}.#{table}" }.join(' ') if ignore_tables

      # dump
      #
      command = "mysqldump #{options} #{ignore_flags} #{credentials} #{db_config['database']}"
      command += " | gzip > #{outfile}"

      LOGGER.info("* Dumping database '#{db_config['database']}' in rails environment '#{Rails.env}' to file '#{outfile}'")
      LOGGER.info("* Command = #{db_config['password'] ? command.gsub(/#{db_config['password']}/, 'XXX') : command}")
      LOGGER.info("* Dump start: #{`date`}")
      `#{command}`
      LOGGER.info("* Dump end: #{`date`}")

      
    end
    
  end    

  #
  #
  def self.BACKGROUND_EXAMPLE
    bp = BackgroundProgress.find_by_id(ENV['BACKGROUND_ID'].to_i) || BackgroundProgress.new
    
    bp.track do
      
      begin
        write_percent(1)
        
        #**********
        # for testing
        #**********
        10.times do |ii|
          write_percent(9 * ii)
          write_output("#{ii}: output at #{9*ii}")
          sleep(1)
        end
        write_percent(100)
        
      rescue
        write_percent(-1)
        raise e
      end # begin / rescue
      
    end # bp.track
  end #     def self.BACKGROUND_EXAMPLE

end
