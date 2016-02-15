require 'date'

class FileAction
  # The format for dates in a filename is is YYYY-MM-DD
  DATEREGEXP = /[0-9]{4}[_-][0-9]{2}[_-][0-9]{2}/
  


  attr_accessor :name, :action

  def initialize(directory, name)
    @name = name
    @path = File.join(directory, name)
    @action = :keep
  end

  def date
    Date.parse(@name.match(DATEREGEXP)[0].gsub('_', '-'))    
  end

  def size
    File.size(@path)
  end

  def perform_action!(logger)
    logger.call "  #{@action} #{@name}"
    File.delete(@path) if @action == :delete
  end

end
    

module Enumerable
  def group_by
    self.inject(Hash.new() { |h, k| h[k] = [] }) { |h, v| h[yield(v)] << v ; h }
  end
end

# to test:
# 
#     (1..12).each { |ii| (1..28).each { |jj| `touch /tmp/2009_#{sprintf("%02i", ii)}_#{sprintf("%02i", jj)}.fred` }}
    
class BackupPruner

  # The format for dates in a filename is is YYYY-MM-DD
  DATEREGEXP = /[0-9]{4}[_-][0-9]{2}[_-][0-9]{2}/
  


  @@logger = method(:puts)    
  cattr_accessor :logger

  def self.prune(directory)
    
    raise "invalid directory specified" unless File.directory?(directory)
    files = []
    Dir.open(directory) { |dir| dir.each { |filename| files << FileAction.new(directory, filename) if filename.match(DATEREGEXP) } }
    # Group files into categories by non-date components
    categories = files.group_by { |f| f.name.gsub(DATEREGEXP, '') }
    @@logger.call("#{categories.keys.size} file groups found")
    
    categories.each do |category, cfiles|
      @@logger.call "Processing files in category #{category} - #{cfiles.size} files"
      # Sort by date
      cfiles = cfiles.sort_by { |f| f.date }

      most_recent = 14

      # Always keep the most recent 30 files; for the rest, keep 1 per
      # week (defaulting to the earliest file if we have a choice) or
      # 1 per month for files over a year old
      if cfiles.size > most_recent
        cfiles[0, cfiles.size - most_recent].group_by { |f| f.date.strftime('%Y week %U') }.each do |week, wfiles|
          next if wfiles.size == 0
          earliest = wfiles.sort_by { |f| f.date }.first
          wfiles.select { |f| f != earliest }.each { |f| f.action = :delete }
        end
      end
      # THIS WILL INTERACT POORLY WITH WEEKLY DELETE UNLESS WEEKLY IS CHANGED...
      # cfiles.group_by { |f| (f.date - (f.date.mday - 1)) }.each do |month, wfiles|
      #   next if wfiles.size == 0
      #   next if (Date.today - month) < 365
      #   latest = wfiles.sort_by { |f| f.date }.last
      #   wfiles.select { |f| f != latest }.each { |f| f.action = :delete }
      # end
      # Delete the files to be deleted
      cfiles.each { |f| f.perform_action!(@@logger) }
    end
    @@logger.call "Done!"
  end
    

end
