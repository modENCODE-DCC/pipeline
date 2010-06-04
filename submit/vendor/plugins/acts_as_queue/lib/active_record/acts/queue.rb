module ActiveRecord
  module Acts #:nodoc:
    module Queue #:nodoc:
      def self.included(base)
        base.extend(ClassMethods)
      end

      # This +acts_as+ extension provides the capabilities for sorting and reordering a number of objects in a queue.
      # The class that has this specified needs to have a +queue_position+ column defined as an integer on
      # the mapped database table.
      #
      # Todo queue example:
      #
      #   class TodoQueue < ActiveRecord::Base
      #     has_many :todo_items, :column => "queue_position"
      #   end
      #
      #   class TodoItem < ActiveRecord::Base
      #     belongs_to :todo_queue
      #     acts_as_queue :scope => :todo_queue
      #   end
      #
      #   todo_queue.first.move_to_bottom_in_queue
      #   todo_queue.last.move_higher
      module ClassMethods
        # Configuration options are:
        #
        # * +column+ - specifies the column name to use for keeping the queue position integer (default: +queue_position+)
        # * +scope+ - restricts what is to be considered a queue. Given a symbol, it'll attach <tt>_id</tt> 
        #   (if it hasn't already been added) and use that as the foreign key restriction. It's also possible 
        #   to give it an entire string that is interpolated if you need a tighter scope than just a foreign key.
        #   Example: <tt>acts_as_queue :scope => 'todo_queue_id = #{todo_queue_id} AND completed = 0'</tt>
        def acts_as_queue(options = {})
          configuration = { :column => "queue_position", :scope => "1 = 1" }
          configuration.update(options) if options.is_a?(Hash)

          configuration[:scope] = "#{configuration[:scope]}_id".intern if configuration[:scope].is_a?(Symbol) && configuration[:scope].to_s !~ /_id$/

          if configuration[:scope].is_a?(Symbol)
            scope_condition_method = %(
              def queue_scope_condition
                if #{configuration[:scope].to_s}.nil?
                  "#{configuration[:scope].to_s} IS NULL"
                else
                  "#{configuration[:scope].to_s} = \#{#{configuration[:scope].to_s}}"
                end
              end
            )
          else
            scope_condition_method = "def queue_scope_condition() \"#{configuration[:scope]}\" end"
          end

          class_eval <<-EOV
            include ActiveRecord::Acts::Queue::InstanceMethods

            def acts_as_queue_class
              ::#{self.name}
            end

            def queue_position_column
              '#{configuration[:column]}'
            end

            #{scope_condition_method}

            before_destroy :remove_from_queue
            before_create  :add_to_queue_bottom
          EOV
        end
      end

      # All the methods available to a record that has had <tt>acts_as_queue</tt> specified. Each method works
      # by assuming the object to be the item in the queue, so <tt>chapter.move_lower</tt> would move that chapter
      # lower in the queue of all chapters. Likewise, <tt>chapter.first?</tt> would return +true+ if that chapter is
      # the first in the queue of all chapters.
      module InstanceMethods
        # Insert the item at the given queue_position (defaults to the top queue_position of 1).
        def queue_insert_at(queue_position = 1)
          insert_at_queue_position(queue_position)
        end

        # Swap queue_positions with the next lower item, if one exists.
        def move_lower_in_queue
          return unless lower_item_in_queue

          acts_as_queue_class.transaction do
            lower_item_in_queue.decrement_queue_position
            increment_queue_position
          end
        end

        # Swap queue_positions with the next higher item, if one exists.
        def move_higher_in_queue
          return unless higher_item_in_queue

          acts_as_queue_class.transaction do
            higher_item_in_queue.increment_queue_position
            decrement_queue_position
          end
        end

        # Move to the bottom of the queue. If the item is already in the queue, the items below it have their
        # queue_position adjusted accordingly.
        def move_to_bottom_in_queue
          return unless in_queue?
          acts_as_queue_class.transaction do
            decrement_queue_positions_on_lower_items
            assume_bottom_queue_position
          end
        end

        # Move to the top of the queue. If the item is already in the queue, the items above it have their
        # queue_position adjusted accordingly.
        def move_to_top_in_queue
          return unless in_queue?
          acts_as_queue_class.transaction do
            increment_queue_positions_on_higher_items
            assume_top_queue_position
          end
        end

        # Removes the item from the queue.
        def remove_from_queue
          if in_queue?
            decrement_queue_positions_on_lower_items
            update_attribute queue_position_column, nil
          end
        end

        # Increase the queue_position of this item without adjusting the rest of the queue.
        def increment_queue_position
          return unless in_queue?
          update_attribute queue_position_column, self.send(queue_position_column).to_i + 1
        end

        # Decrease the queue_position of this item without adjusting the rest of the queue.
        def decrement_queue_position
          return unless in_queue?
          update_attribute queue_position_column, self.send(queue_position_column).to_i - 1
        end

        # Return +true+ if this object is the first in the queue.
        def first_in_queue?
          return false unless in_queue?
          self.send(queue_position_column) == 1
        end

        # Return +true+ if this object is the last in the queue.
        def last_in_queue?
          return false unless in_queue?
          self.send(queue_position_column) == bottom_queue_position_in_queue
        end

        # Return the next higher item in the queue.
        def higher_item_in_queue
          return nil unless in_queue?
          acts_as_queue_class.find(:first, :conditions =>
            "#{queue_scope_condition} AND #{queue_position_column} = #{(send(queue_position_column).to_i - 1).to_s}"
          )
        end

        # Return the next lower item in the queue.
        def lower_item_in_queue
          return nil unless in_queue?
          acts_as_queue_class.find(:first, :conditions =>
            "#{queue_scope_condition} AND #{queue_position_column} = #{(send(queue_position_column).to_i + 1).to_s}"
          )
        end

        # Test if this record is in a queue
        def in_queue?
          !send(queue_position_column).nil?
        end

        private
          def add_to_queue_top
            increment_queue_positions_on_all_items
          end

          def add_to_queue_bottom
            self[queue_position_column] = bottom_queue_position_in_queue.to_i + 1
          end

          # Overwrite this method to define the scope of the queue changes
          def queue_scope_condition() "1" end

          # Returns the bottom queue_position number in the queue.
          #   bottom_queue_position_in_queue    # => 2
          def bottom_queue_position_in_queue(except = nil)
            item = bottom_item_in_queue(except)
            item ? item.send(queue_position_column) : 0
          end

          # Returns the bottom item
          def bottom_item_in_queue(except = nil)
            conditions = queue_scope_condition
            conditions = "#{conditions} AND #{self.class.primary_key} != #{except.id}" if except
            acts_as_queue_class.find(:first, :conditions => conditions, :order => "#{queue_position_column} DESC")
          end

          # Forces item to assume the bottom queue_position in the queue.
          def assume_bottom_queue_position
            update_attribute(queue_position_column, bottom_queue_position_in_queue(self).to_i + 1)
          end

          # Forces item to assume the top queue_position in the queue.
          def assume_top_queue_position
            update_attribute(queue_position_column, 1)
          end

          # This has the effect of moving all the higher items up one.
          def decrement_queue_positions_on_higher_items(queue_position)
            acts_as_queue_class.update_all(
              "#{queue_position_column} = (#{queue_position_column} - 1)", "#{queue_scope_condition} AND #{queue_position_column} <= #{queue_position}"
            )
          end

          # This has the effect of moving all the lower items up one.
          def decrement_queue_positions_on_lower_items
            return unless in_queue?
            acts_as_queue_class.update_all(
              "#{queue_position_column} = (#{queue_position_column} - 1)", "#{queue_scope_condition} AND #{queue_position_column} > #{send(queue_position_column).to_i}"
            )
          end

          # This has the effect of moving all the higher items down one.
          def increment_queue_positions_on_higher_items
            return unless in_queue?
            acts_as_queue_class.update_all(
              "#{queue_position_column} = (#{queue_position_column} + 1)", "#{queue_scope_condition} AND #{queue_position_column} < #{send(queue_position_column).to_i}"
            )
          end

          # This has the effect of moving all the lower items down one.
          def increment_queue_positions_on_lower_items(queue_position)
            acts_as_queue_class.update_all(
              "#{queue_position_column} = (#{queue_position_column} + 1)", "#{queue_scope_condition} AND #{queue_position_column} >= #{queue_position}"
           )
          end

          # Increments queue_position (<tt>queue_position_column</tt>) of all items in the queue.
          def increment_queue_positions_on_all_items
            acts_as_queue_class.update_all(
              "#{queue_position_column} = (#{queue_position_column} + 1)",  "#{queue_scope_condition}"
            )
          end

          def insert_at_queue_position(queue_position)
            remove_from_queue
            increment_queue_positions_on_lower_items(queue_position)
            self.update_attribute(queue_position_column, queue_position)
          end
      end 
    end
  end
end
