# used as a mixin
#
# your customer class should have
#     include NewsletterEditor::Model::Customer
module NewsletterEditorMixin
  module Customer
    def self.included(model)
      model.has_many :newsletter_recipients
    end
  end
end
