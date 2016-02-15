module DbDump

  # Dump the current database into a file for backup purposes

  def DbDump.dump_for_backup(path, ignore_tables = nil)

    # Set up logging for either rails default or within job_runner or within rake
    logger = RAILS_DEFAULT_LOGGER if defined?(RAILS_DEFAULT_LOGGER)
    logger = JobRunner::LOGGER if defined?(JobRunner::LOGGER)
    logger = Logger.new(STDOUT) unless logger

    db_config = YAML.load_file("#{Rails.root}/config/database.yml")
    db_config = db_config[Rails.env] if db_config
    logger.error("Database configuration for environment '#{Rails.env}' does not exist!") && return unless db_config

    options = "--create-options --single-transaction --quick"
    options << " --host #{db_config['host']}" if db_config['host']
    options << " --port #{db_config['port']}" if db_config['port']

    date_postfix = Date.today.strftime('%Y_%m_%d')
    outfile = "#{path}#{'/' unless path[-1].chr == '/'}#{db_config['database']}_#{date_postfix}.sql"
    # Passing password on command line isn't ideal, but ok if no-one else is on the box... don't use on a shared box!!!!
    credentials = "--user=#{db_config['username']} #{"--password=#{db_config['password']}" if db_config['password']}"
    logger.info("Dumping database '#{db_config['database']}' in rails environment '#{Rails.env}' to file '#{outfile}'")

    logger.info("Ignoring the following tables: #{ignore_tables.inspect}") if ignore_tables
    ignore_flags = ignore_tables.map { |table| "--ignore_table=#{db_config['database']}.#{table}" }.join(' ') if ignore_tables

    # Note: Inner 'sh -c' usage below allows us to grab the stderr of the output

    command = "mysqldump #{options} #{ignore_flags} #{credentials} #{db_config['database']} > #{outfile}"
    logger.info(db_config['password'] ? command.gsub(/#{db_config['password']}/, 'XXX') : command)
    logger.info("Dump start: #{`date`}")
    mysqldump = IO.popen("sh -c '#{command}' 2>&1")
    mysqldump.readlines().each { |l| logger.info("  " + l) }
    logger.info("Dump end: #{`date`}")

    logger.info("Compressing #{outfile}")
    command = "echo 'n' | gzip #{outfile}"
    logger.info(command)
    gzip = IO.popen("sh -c '#{command}' 2>&1")
    gzip.readlines().each { |l| logger.info("  " + l) }

    return

  end

end
