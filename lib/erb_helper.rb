require 'erb'

class ErbHelper
  
  ######################################################################
  # Fill in a template that's in a file someplace and return the result
  #
  #   filename - name of file containing template data
  #   data     - hash of variable->value, where variable is a symbol
  #
  # E.g.: 
  #   ------------
  #   file = 
  #       Name: <%= name %>
  #       Things:
  #       <% things.each do |thing| %>
  #         * <%= thing %>
  #       <% end %>
  #  
  #   data = { :name => 'Pete', :things => [ 'box', 'apple', 'rock' ] }
  #   ------------
  #
  # Notes:
  # * don't use initial caps for names (ie :NAME) - that will define a global constant...
  # * reserved variable names = :template_filename, :template_data, :template_text
  #
  ######################################################################
  
  def self.template_file(template_filename, template_data)
    # Read the template
    template_text = IO.readlines(template_filename).join
   
    bb = binding()
 
    # Instantiate all the variables in the data hash (use for instead of block
    # iteration so that variables bind at upper context)
    for var in template_data.keys
      bb.eval("#{var.id2name} = template_data[var]")
    end

    
    # Do the substitution and return (must pass in current binding to get variables from above)
    return ERB.new(template_text, 0, "%<>").result(bb)
  end
  
end
