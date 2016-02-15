# Example:
#  <% form_for :user, :url => { :action => :edit }, :builder => LabelBuilder do |form| %>
#    <%= form.text_field :username %>
#  <% end %>
#
#  ... outputs ...
#
# <form method="post" action="/managers/coworker_management/edit">
#   <label for="user_username">Username</label>
#   <input type="text" id="user_username" name="user[username]">
# </form>
#

class LabelBuilder < ActionView::Helpers::FormBuilder
  def self.create_labelled_field(method_name)
    define_method(method_name) do |field_name,*args|
      options_index = method_name =~ /select|check_box|radio_button/ ? 1 : 0
      label = nil
      field_id = nil
      unless args.nil? or args[options_index].nil?
        label ||= args[options_index][:label]
        field_id ||= args[options_index][:id]
      end
      label = label.nil? ? field_name.to_s : label
      field_id = field_id.nil? ? "#{@object_name}_#{field_name}" : field_id

      # add method_name to the class so that, eg., radio buttons can be styled
      # separately from text inputs.
      @template.content_tag("div", (
        @template.content_tag("label", label.humanize, :for => field_id ) + super),
        :class => "form_field #{method_name}")
    end
  end
  
  field_helpers.each do |name|
    unless name == 'hidden_field'
      create_labelled_field(name)
    end
  end
  create_labelled_field('select')
end