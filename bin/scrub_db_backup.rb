#!/usr/local/bin/ruby

# scrub useless tables from a recent database backup
#
# BUGS:
#    * should scramble customer information

require 'date'

date_string = (Date.today - 1).strftime("%Y_%m_%d")
infile = "/home/autorun/external-db-backups/smart_railscart_#{date_string}.sql.gz"
outfile = "/share/development_databases/sf_web_scrubbed.sql.gz"

# There's prob an existing out there from the last run.
# Detect if we're going to fail before we pollute this existing resource.
#
raise "input #{infile} does not exist - ERROR!" unless File.file?(infile)

puts "Scrubbing #{infile} and writing to /share ..."

puts `gzip -d -c #{infile} | egrep -v 'INSERT INTO .(sessions|ab_test_visitors|ab_test_results|origins|url_tracks)' | egrep -v 'USE .smart_railscart' | gzip -c > #{outfile}`

puts "Done: file #{outfile} now exists! ********************"
