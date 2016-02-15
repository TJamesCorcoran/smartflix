class RenameAbTestsCol < ActiveRecord::Migration
  def up
    rename_column :ab_tests, :flight, :ordinal
  end

  def down
    rename_column :ab_tests, :ordinal, :flight
  end
end
