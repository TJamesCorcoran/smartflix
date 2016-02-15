# from
#    https://github.com/collectiveidea/delayed_job
#
Delayed::Worker.backend = :active_record
Delayed::Worker.delay_jobs = Rails.env.production?
