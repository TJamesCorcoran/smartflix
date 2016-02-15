# Because of a cron job on neon, we expect that a scrubbed import file exists on neon.
#
#

# putting => :environment in the task gets us individual ActiveRecords, but not Base
require File.dirname(__FILE__) + '/../../config/environment'

namespace :db do

  desc "overwrite your devel database with recent live data"
  import_file = "/share/development_databases/sfw_scrubbed.sql.gz"

  task :show => :environment do |t|
    puts `ls -lgA #{import_file}`
  end

  task :import => :environment do |t|

    raise "only in development" unless Rails.env == "development" 
    raise "import file doesn't exist - #{import_file}" unless File.exist?(import_file)

    localdb = ActiveRecord::Base.configurations["development"]["database"]

    # IF   live railscart db is at version 100
    # AND  local devel db is at version 110
    # AND  migration 105 adds table "foobar"
    # THEN importing the .sql file will not destroy file "foobar", and
    #      the migrations_info table will show that migration 105 needs to
    #      be run, but running it will complain "foobar already exists!"
    # SO:  just kill the database and then recreate

    before = Time.now
    puts " Expected duration: ~ 20 minutes"
    puts " * starting at #{before}"
    puts " * dropping old database"

    ActiveRecord::Base.connection.execute("DROP DATABASE #{localdb}")
    ActiveRecord::Base.connection.execute("CREATE DATABASE #{localdb}")
    
    raise "import file #{import_file} does not exist" if ! File.file? import_file
    ctime = Date.parse(File.ctime(import_file).strftime("%Y-%m-%d"))
    raise "import file #{import_file} is stale" if ctime  < (DateTime.now - 3)

    puts " * begining import of  #{import_file} into db '#{localdb}'"    
    `gzip -d -c #{import_file} | mysql -uroot -D#{localdb}`
    puts "* done db import! ********************"
  end
  
  
end
