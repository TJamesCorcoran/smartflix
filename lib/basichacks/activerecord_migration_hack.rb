# you will have to put this line in your migration:
#   require 'vendor/plugins/basichacks/lib/activerecord_migration_hack'

class ActiveRecord::Migration

  def self.move_table_to_backup(src)
    backup = "#{src.to_s}_old"
    rename_table src, backup
    execute ("CREATE TABLE #{src} LIKE #{backup}")
  end

end
