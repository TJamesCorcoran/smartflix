# 7 Jan 2015
# Suz reported search bug on SF.
# Investigation revealed that search was blowing up 
# bc of undefined alphabet conversion in file
#     app/controllers/store_controller
# line
#     Video.search(query ...)
# solution here:
#     https://github.com/pat/thinking-sphinx/issues/632

class ThinkingSphinx::Excerpter
  def excerpt!(text)
    ThinkingSphinx::Connection.take do |connection|
      connection.query(statement_for(text)).first['snippet']
    end
  end
end
