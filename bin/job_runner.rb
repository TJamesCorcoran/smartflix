#! /usr/bin/ruby
require File.dirname(__FILE__) + '/../vendor/plugins/job_runner/lib/job_runner'
success = JobRunner::offer(:do, :charge_pending)

# unix-style return codes
exit (success ? 0 : -1)

