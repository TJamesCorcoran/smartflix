class Project < ActiveRecord::Base
  attr_protected # <-- blank means total access


  belongs_to :customer
  has_many :updates, :class_name => 'ProjectUpdate', :order => 'id'
  has_many :images, :through => :updates, :order => 'id'
  has_many :comments, :as => :parent, :order => 'id'
  belongs_to :inspired_by, :class_name => 'Project'
  has_many :inspirees, :class_name => 'Project', :foreign_key => 'inspired_by_id'

  has_many :favorite_project_links
  has_many :favorite_of_customers, :through => :favorite_project_links, :source => :customer

  validates_length_of :title, :minimum => 2

  # We use mass assignment, so limit inputs for security
  attr_accessible :title, :status, :inspired_by_id

  # A project can have one of several statuses
  enum_field :status, { :constant => :SOMEDAY,       :select => "Planning on it someday", :display => "Future" },
                      { :constant => :JUST_STARTING, :select => "Just getting started",   :display => "Starting" },
                      { :constant => :IN_PROGRESS,   :select => "Work in progress",       :display => "In Progress" },
                      { :constant => :FINISHED,      :select => "Finished!",              :display => "Finished" }

  # Default image is the first image of the most recent update that has an images
  def default_image
    updates.select { |u| u.images.count > 0 }.last.andand.images.andand.first
  end

  # Methods to get the initial update or subsequent updates
  def initial_update
    updates.first
  end
  def subsequent_updates
    updates[1,updates.count-1]
  end

  # Is this project the favorite of some customer?
  def is_favorite_of?(customer)
    customer && self.favorite_of_customers.find_by_customer_id(customer.id)
  end

end
