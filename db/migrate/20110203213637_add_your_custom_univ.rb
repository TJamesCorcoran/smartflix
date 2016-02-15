class AddYourCustomUniv < ActiveRecord::Migration
  def self.up
    University.create_new(:title_id_list => [], 
                          :name => "Your Custom University", 
                          :category => Category[108],
                          :price => 22.95,
                          :featured_product => Video[4236])
  end

  def self.down
    University.find_by_name("Your Custom University").andand.destroy_with_children
  end
end
