class Comment < ActiveRecord::Base
  belongs_to :parent, :polymorphic => true
  belongs_to :author, :class_name => 'Customer', :foreign_key => 'customer_id'
end
