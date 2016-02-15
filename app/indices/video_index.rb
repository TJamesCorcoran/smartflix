ThinkingSphinx::Index.define :video, :with => :active_record do

    indexes :name, :sortable => true
#    indexes :author_name, :sortable => true
    indexes :description, :sortable => true

end
