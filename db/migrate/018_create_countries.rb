class CreateCountries < ActiveRecord::Migration

  def self.up

    create_table(:countries, :primary_key => 'country_id') do |t|
      t.column :name, :string, :null => false
    end

    # Pre-populate this table; we specify the IDs directly to ensure
    # that they are the same as in Zencart to make the mapping easier,
    # and to do that we need to do direct SQL since create always uses
    # default IDs

    execute "INSERT INTO countries (country_id, name) VALUES (223, 'United States')"
    execute "INSERT INTO countries (country_id, name) VALUES (38, 'Canada')"

  end

  def self.down
    drop_table :countries
  end
end
