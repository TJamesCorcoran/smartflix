#! /usr/local/bin/ruby

# Utility script for pruning out old session data

# Make default rails environment be development
Rails.env = "development"

# Parse out any additional environment variables before we load up
# rails, and add them to the environment
env = ARGV.select { |arg| arg.match(/^\w+=.*$/) }
env.each { |arg| ENV.send(:[]=, *arg.match(/^(\w+)=(.*)$/)[1,2]) }

# Load rails
puts "Loading rails..."
require File.dirname(__FILE__) + '/../config/environment'

total_deleted = 0

while true

  # This may seem roundabout, but simpler ways ran into obstacles...
  puts 'Finding IDs to delete'
  to_delete = ActiveRecord::Base.connection.select_all("SELECT sessions.id
                                                          FROM sessions
                                                     LEFT JOIN origins ON sessions.id = origins.session_id
                                                         WHERE ISNULL(origins.session_id)
                                                           AND (DATEDIFF(NOW(), sessions.updated_at) > 60)
                                                         LIMIT 1000;")

  ids_to_delete = to_delete.map { |record| record['id'] }

  if ids_to_delete.empty?
    puts "Done! No candidate IDs found"
    break
  end

  total_deleted += ids_to_delete.size

  puts "Deleting #{ids_to_delete.size} IDs (#{total_deleted} so far)"
  ActiveRecord::Base.connection.delete("DELETE FROM sessions WHERE sessions.id IN (#{ids_to_delete.join(',')})")

end
