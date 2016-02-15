class JobStatus < ActiveResource::Base

  if Rails.env == 'production'
    self.site = "http://status:WhatGoesOn@jobs.smartflix.com/"
  else
    self.site = "http://status:WhatGoesOn@localhost:4000/"
  end

  self.timeout = 10

  def self.track_start(task_name)
    jobname = task_name
    hostname = `hostname`.strip
    appname = Rails.application.class.parent_name
    @@status = JobStatus.create(:name => jobname,
                                :server => hostname, 
                                :application => appname, 
                                :start_time => DateTime.now(),
                                :end_time => DateTime.now(),
                                :status => 1)
  rescue ActiveResource::TimeoutError => e
    # Timeout silently
  rescue Exception => e
    # Fail silently
  end

  def self.track_failure(log)
    @@status.end_time = DateTime.now()
    @@status.log = log
    @@status.status = 3
    @@status.save
  rescue ActiveResource::TimeoutError => e
    # Timeout silently
  rescue Exception => e
    # Fail silently
  end

  def self.track_success(log)
    @@status.end_time = DateTime.now()
    @@status.log = log
    @@status.status = 2
    @@status.save
  rescue ActiveResource::TimeoutError => e
    # Timeout silently
  rescue Exception => e
    # Fail silently
  end

end
