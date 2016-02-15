class RenameDelayedJobsKey < ActiveRecord::Migration
  def self.up
    execute "ALTER TABLE delayed_jobs CHANGE delayed_job_id id  integer NOT NULL AUTO_INCREMENT"
  end

  def self.down
    execute "ALTER TABLE delayed_jobs CHANGE id delayed_job_id   integer NOT NULL AUTO_INCREMENT"
  end
end
