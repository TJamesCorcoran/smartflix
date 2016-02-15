class AbTestVisitors < ActiveRecord::Migration
  def self.up
    create_table(:ab_test_visitors, :primary_key => 'ab_test_visitor_id') do |t|
    end
  end

  def self.down
    drop_table :ab_test_visitors
  end
end
