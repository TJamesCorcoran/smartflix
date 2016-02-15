# SMARTFLIX
#

ruby '1.9.3'

source 'https://rubygems.org'

#----------
# everything outside of an explicit group is in the group
#    :default
#----------

gem 'rails', '3.2.13'

# 24 Jun 2013: 
#   * current live version of mysql2 is 0.3.11
#   * this works w almost everything, BUT...
#   * for thinking_sphinx v3, we need 0.3.12b6 
#     ref: http://stackoverflow.com/questions/16321211/thinking-sphinx-search-returns-object-doesnt-support-inspect
gem "mysql2", "0.3.13" #, :git => "http://github.com/brianmario/mysql2"


gem "activemerchant"
gem "agent_orange"
gem "andand"
gem "bundler"
gem "capistrano"
gem "daemons", "1.0.10"  # necessary for delayed_jobs
gem "delayed_job", "3.0.0"
gem "delayed_job_active_record"  # <-- bc we store delayed jobs in activerecord
gem "dynamic_form"
gem "exception_notification", "3.0.1", :require => "exception_notifier"
gem "execjs"              # http://stackoverflow.com/questions/6282307/execjs-and-could-not-find-a-javascript-runtime
gem "google-adwords-api"
gem "hpricot"
gem "jquery-rails", "2.3.0"  # 27 Jun 2013 - http://stackoverflow.com/questions/16844411/rails-active-admin-deployment-couldnt-find-file-jquery-ui
gem "mechanize", "2.3" # ???
gem "money"
gem "net-ssh", "2.6.8"  # ensure that cap deploy works -- http://stackoverflow.com/questions/21560297/capistrano-sshauthenticationfailed-not-prompting-for-password
gem "passenger", "4.0.1"
gem "rvm-capistrano"
gem "sanitize"
gem "soundmanager-rails"
gem "thin"
gem "thinking-sphinx", "~> 3.1.1"
gem "therubyracer" # needs to come after 'thinking-sphinx' or else get an error
gem "will_paginate", "~> 3.0"

#----------
# ???
#----------
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem 'uglifier', '>= 1.0.3'
end

#----------
# now three groups, one for each development environment
#----------

group :production do
  # nothing
end

group :test do
  gem "mocha" , :require => false
  gem "shoulda-context"
end


group :development do 
#  gem "query_reviewer", :git => "https://github.com/nesquena/query_reviewer.git"

#  gem 'flay'
#  gem 'flog'
#  gem 'reek'
end
