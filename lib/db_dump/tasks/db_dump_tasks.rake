require 'yaml'
require 'vendor/plugins/db_dump/lib/db_dump'

namespace :db do

  desc "Dump the current database; output location must be specified with OUTPATH=<path>"
  task :dump_for_backup do
    (puts('You must specifiy OUTPATH when calling rake db:dump_for_backup') ; exit) unless ENV['OUTPATH']
    ignore_tables = ENV['IGNORE_TABLES'].split(/,/) if ENV['IGNORE_TABLES']
    DbDump.dump_for_backup(ENV['OUTPATH'], ignore_tables)
  end

end
