module ActsAsNotable
  def acts_as_notable()
    has_many :notes, :as => :notable
    
    define_method(:add_note) do |text, employee_id|
      Note.create!(:notable => self, :note => text, :employee_id => employee_id)
    end

  end
 
end

# Extend ActiveRecord to have acts_as_notable method
ActiveRecord::Base.extend ActsAsNotable

