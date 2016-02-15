# Define some custom exceptions that we can throw
class TrackingColumnNotFound < StandardError
end
class DataTypeNotSupported < StandardError
end
class ReferenceColumnNotFound < StandardError
end
class MultipleReferencesNotSupported < StandardError
end
class ReferenceNotAllowed < StandardError
end

module ChangeTracker

  # XXXFIX P4: Consider simply extending Base rather than doing this dance if nothing else needed
  def ChangeTracker.included(base)
    base.extend(ClassMethods)
  end

  module ClassMethods

    # Track the changes on a particular database column. Changes are
    # tracked using another model that has been specifically set up to
    # do the tracking. Adds or changes the following methods (using the
    # example of model Widget, tracked by WidgetCountUpdate, where
    # changes can be linked to CustomerOrder and IncomingShipment):
    #
    # On the Widget class, where track_changes_on is called:
    #
    #   count=            -- modified so that all later-saved changes are tracked
    #
    #   set_<field>       -- set a field, tracking a reference
    #   increment_<field> -- increment a field, tracking a reference
    #   decrement_<field> -- decrement a field, tracking a reference
    #
    # The above methods take two optional options:
    #
    #   :reference        -- the referred object related to the change in value
    #   :note             -- a note to store with the change, requires a note
    #                        field on the tracking table
    #
    #   <field>_updates   -- returns all updates that have ever occured on
    #                        the field
    #
    # On the tracking class, WidgetCountUpdate
    #
    #   widget            -- returns the widget this update applies to
    #
    #   reference         -- returns the customer_order or incoming_shipment
    #                        related to this inventory change
    #
    # On the CustomerOrder and IncomingShipment classes
    #
    #   widget_count_update -- the update caused by this order or
    #                          shipment
    #
    # Valid options include
    #
    # :tracked_by - model used to track the changes (defaults to
    #               <this_model>_<field>_updates)
    #
    # :tracking_column - where diffs are tracked (defaults to an
    #                    automatic guess of the right column name, based
    #                    on assumption that it's the only non-date
    #                    non-id non-type field
    #
    # :tracking_reference_columns - columns that polymorphicly point
    #                               to an instance of another model that
    #                               explains a given change (defaults to
    #                               automatic guesses of the right
    #                               column names)
    #
    # :allowed_references - list of active record models that can be
    #                       polymorphically pointed to by the tracking
    #                       table; used to set up polymorphic references
    #
    # :store_type        - { :delta [DEFAULT] | :absolute } 
    #                          - stores history as either deltas in values or as absolute values

    def track_changes_on(field, options = {})

      ActiveSupport::Deprecation.silenced = true

      # Check options and set up all defaults
      options.assert_valid_keys(:tracked_by, :tracking_column, :tracking_reference_columns, :allowed_references, :store_type)
      options[:tracked_by] ||= "#{self.to_s.underscore}_#{field.to_s.underscore}_updates"
      options[:tracking_class] = const_get(ActiveSupport::Inflector.singularize(options[:tracked_by]).camelize)
      options[:tracking_column] ||= options[:tracking_class].send(:detect_tracking_column)
      options[:tracking_reference_columns] ||= options[:tracking_class].send(:detect_reference_columns) if options[:allowed_references]
      options[:allowed_references] ||= []
      options[:allowed_references] = [options[:allowed_references]] if !options[:allowed_references].is_a?(Array)


      raise ":store_type must be { :delta | :absolute}, not #{options[:store_type]}" if options[:store_type] && ! [:delta, :absolute].include?(options[:store_type])
      store_type = options[:store_type] || :delta

      # Add different utility methods depending on the type of data we're tracking
      column = self.columns.detect { |c| c.name.to_s == field.to_s }
      raise TrackingColumnNotFound, "Tracking column #{field} not found in tracks_changes_on" if column.nil?
      case column.type
      when :integer, :decimal
        add_numeric_track_changes_on(field, options, store_type)
      when :string
        add_string_track_changes_on(field, options, store_type)
      else
        raise DataTypeNotSupported, "Data type #{column.type} for #{column.name} not currently supported in track_changes_on"
      end

      # make two things point to each other
      #

      # 1) The primary class has many "updates" 
      #
      self.instance_eval do
        updates_name = "#{field}_updates".to_sym
        class_name   = ActiveSupport::Inflector.singularize(options[:tracked_by].to_s).camelize
        has_many updates_name, :class_name => class_name
      end

      # 2) The "updates" class needs to point to the primary class
      #
      belongs_to_class_name = self.to_s
      options[:tracking_class].instance_eval do
        belongs_to belongs_to_class_name.underscore.to_sym
      end

      # Add appropriate polymorphic belongs_to and has_many entries to the reference classes
      if options[:allowed_references].size > 0
        options[:tracking_class].instance_eval do
          belongs_to :reference, :polymorphic => true
        end
        options[:allowed_references].each do |reference|
          # "bills"     --> "bill"
          # "customers" --> "customer"
          # "address"   --> "address"
          #
          # yes, it would be better to delve deep into 
          #   ActiveSupport::Inflector
          # and hack it to be clean
          #
          # http://blog.hasmanythrough.com/2006/5/17/pluralizations

          ref_name = (reference.to_s[-2,2] == "ss") ? reference.to_s.camelize : ActiveSupport::Inflector.singularize(reference.to_s.camelize)
          const_get(ref_name).instance_eval do
            has_many ActiveSupport::Inflector.pluralize(options[:tracked_by].to_s).to_sym, :as => :reference
          end
        end
      end

      ActiveSupport::Deprecation.silenced = false

    end

    private

    # Automatically detect the likely :tracking_column
    def detect_tracking_column
      possibilities = self.columns.collect(&:name).reject { |c| c.match(/(^id$)|(_id$)|(_on$)|(_at$)|(_type$)|(^note$)/) }
      raise TrackingColumnNotFound, 'Could not automatically detect tracking column in tracks_changes_on' if possibilities.size != 1
      return possibilities.first
    end

    # Automatically detect the likely :tracking_reference_columns
    def detect_reference_columns
      column_names = self.columns.collect(&:name)
      reference_types = column_names.select { |c| c.match(/_type$/) }
      raise ReferenceColumnNotFound, 'Could not automatically detect reference columns in tracks_changes_on' if reference_types.size != 1
      reference_base = reference_types.first.match(/(.*)_type/)[1]
      reference = column_names.detect { |c| c.match(/#{reference_base}_id/) }
      raise ReferenceIdColumnNotFound, "Could not find matching foreign key ID column for #{reference_types.first} in tracks_changes_on" if reference.nil?
      return reference_base
    end

    # Change the assignment method to remember the change, and hook save
    # to store the tracking info for numeric changes

    def add_numeric_track_changes_on(field, options, store_type)

      self.instance_eval do

        # Replace the simple set of the variable, optionally tracking a
        # reference (we need to use *args since blocks don't allow
        # default arguments)

        define_method("#{field}=".to_sym) do |value, *args|

          # Skip tracking if there isn't an actual change to the value
          # 24 Feb 2014 return write_attribute(field, value) if read_attribute(field) == value

          arg_options = args.first
          if arg_options
            arg_options.assert_valid_keys(:reference, :note)
            reference = arg_options[:reference]
            note = arg_options[:note]
          end

          # Make sure the supplied reference (if any) is allowed
          if reference
            reference_type = reference.class.to_s.underscore.to_sym
            if !options[:allowed_references].include?(reference_type)
              raise ReferenceNotAllowed, "Reference to type #{reference_type} not allowed; add it to the :allowed_references for track_changes_on. Only allow #{options[:allowed_references].inspect}"
            end
          end

          # Track the original value and each new value (with the
          # optional reference to another object and/or note that
          # explains the change) that gets set before a save happens as
          # a list of tuples

          if (!self.instance_variable_get("@#{field}_previous_values"))
            self.instance_variable_set("@#{field}_previous_values", []) 
            self.instance_variable_get("@#{field}_previous_values") << [self.send(field), nil, nil]
          end
          self.instance_variable_get("@#{field}_previous_values") << [value, reference, note]

          write_attribute(field, value)

        end

        # A new setter method, called set_<field> that can track a reference or store a note
        define_method("set_#{field}") do |value, *arg_options|
          self.send("#{field}=".to_sym, value, *arg_options)
        end

        # A new setter method, called increment_<field> that can track a reference or store a note
        define_method("increment_#{field}") do |increment, *arg_options|
          self.send("#{field}=".to_sym, self.send("#{field}") + increment, *arg_options)
        end

        # A new setter method, called decrement_<field> that can track a reference or store a note
        define_method("decrement_#{field}") do |decrement, *arg_options|
          self.send("#{field}=".to_sym, self.send("#{field}") - decrement, *arg_options)
        end

        # Hook on save and make sure the changes are stored
        after_save do |record|

          previous_values = record.instance_variable_get("@#{field}_previous_values")

          # Don't track on creation
          #
          if (previous_values)

            # Track each change from the previous value to the current value that followed it
            previous_value = nil
            previous_values.each do |current_value, reference, note|
              if previous_value &&
                  
                store_val = (store_type == :delta) ? (current_value - previous_value) : current_value
                create_options = { options[:tracking_column].to_sym => store_val,
                                   self.class.to_s.underscore.to_sym => record }
                if reference
                  create_options[options[:tracking_reference_columns].to_sym] = reference
                end
                if note
                  create_options[:note] = note
                end
                ret = options[:tracking_class].create(create_options)
              end
              previous_value = current_value
            end

            # Clear stored original values, since these changes are now tracked
            record.instance_variable_set("@#{field}_previous_values", nil)

          end

        end

      end

    end



    def add_string_track_changes_on(field, options, store_type)

      raise "must be :absolute store type for strings" unless store_type == :absolute

      self.instance_eval do

        # Replace the simple set of the variable, optionally tracking a
        # reference (we need to use *args since blocks don't allow
        # default arguments)

        define_method("#{field}=".to_sym) do |value, *args|

          # Skip tracking if there isn't an actual change to the value
          # return write_attribute(field, value) if read_attribute(field) == value



          arg_options = args.first
          if arg_options
            arg_options.assert_valid_keys(:reference, :note)
            reference = arg_options[:reference]
            note = arg_options[:note]
          end

          # Make sure the supplied reference (if any) is allowed
          if reference
            reference_type = reference.class.to_s.underscore.to_sym
            if !options[:allowed_references].include?(reference_type)
              raise ReferenceNotAllowed, "Reference to type #{reference_type} not allowed; add it to the :allowed_references for track_changes_on. Only allow #{options[:allowed_references].inspect}"
            end
          end

          # Track the original value and each new value (with the
          # optional reference to another object and/or note that
          # explains the change) that gets set before a save happens as
          # a list of tuples

          if (!self.instance_variable_get("@#{field}_previous_values"))
            self.instance_variable_set("@#{field}_previous_values", []) 
            self.instance_variable_get("@#{field}_previous_values") << [self.send(field), nil, nil]
          end
          self.instance_variable_get("@#{field}_previous_values") << [value, reference, note]

          write_attribute(field, value)

        end

        # A new setter method, called set_<field> that can track a reference or store a note
        define_method("set_#{field}") do |value, *arg_options|
          self.send("#{field}=".to_sym, value, *arg_options)
        end

        # Hook on save and make sure the changes are stored
        after_save do |record|

          previous_values = record.instance_variable_get("@#{field}_previous_values")

          # Don't track on creation
          #
          if (previous_values)

            # Track each change from the previous value to the current value that followed it
            previous_value = nil
            previous_values.each do |current_value, reference, note|
              if previous_value &&
                  
                store_val = current_value
                create_options = { options[:tracking_column].to_sym => store_val,
                                   self.to_s.underscore.to_sym => record }
                if reference
                  create_options[options[:tracking_reference_columns].to_sym] = reference
                end
                if note
                  create_options[:note] = note
                end
                ret = options[:tracking_class].create(create_options)
              end
              previous_value = current_value
            end

            # Clear stored original values, since these changes are now tracked
            record.instance_variable_set("@#{field}_previous_values", nil)

          end

        end

      end

    end

  end

end
