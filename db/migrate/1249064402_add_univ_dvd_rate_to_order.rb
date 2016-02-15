class AddUnivDvdRateToOrder < ActiveRecord::Migration
  def self.up
    add_column :orders, :univ_dvd_rate, :integer
    execute("update orders set univ_dvd_rate = 3 where university_id")

    table_name = "orders"
    col_name = "univ_dvd_rate"
    updates_table_name = "#{table_name.singularize}_#{col_name}_updates"
    create_table updates_table_name do |t|
      t.integer col_name
      t.string 'reference_type'
      t.integer 'reference_id'
      t.timestamps
    end


  end

  def self.down
    remove_column :orders, :univ_dvd_rate

    table_name = "orders"
    col_name = "univ_dvd_rate"
    updates_table_name = "#{table_name.singularize}_#{col_name}_updates"
    drop_table updates_table_name

  end
end
