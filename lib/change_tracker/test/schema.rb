ActiveRecord::Schema.define(:version => 1) do

  create_table :widgets, :force => true do |t|
    t.column :quantity, :integer, :null => false
  end

  create_table :widget_quantity_updates, :force => true do |t|
    t.column :widget_id, :integer, :null => false
    t.column :change, :integer, :null => false
  end

  create_table :gidgets, :force => true do |t|
    t.column :quantity, :integer, :null => false
  end

  create_table :gidget_quantity_updates, :force => true do |t|
    t.column :gidget_id, :integer, :null => false
    t.column :change_in_quantity, :integer, :null => false
    t.column :reference_id, :integer, :null => true
    t.column :reference_type, :string
    t.column :note, :string, :null => true
  end

  create_table :arrivals, :force => true do |t|
  end

  create_table :departures, :force => true do |t|
  end

  create_table :didgets, :force => true do |t|
    t.column :quantity, :integer, :null => false
  end

  create_table :didget_changes, :force => true do |t|
    t.column :didget_id, :integer, :null => false
    t.column :misleading_difference, :integer, :null => false
    t.column :difference, :integer, :null => false
    t.column :misleading_id, :integer, :null => true
    t.column :misleading_type, :string
    t.column :reference_id, :integer, :null => true
    t.column :reference_type, :string
  end

end
