#!/bin/bash

# source environment
. /usr/local/rvm/environments/ruby-1.9.3-p429


cd /home/smart/rails/sfw/current/
RAILS_ENV=production rails runner script/job_runner $1  EMAIL_PREFIX=SF LOG_EMAIL=xyz@smartflix.com 
