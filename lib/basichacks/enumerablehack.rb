require 'andand'
module Enumerable
  def destroy_all
    self.each { |x| x.destroy }
  end

  # depends on
  #     vendor/plugins/basichacks/lib/activerecordhack.rb
  def destroy_all_and_children(child_funcs)
    self.each { |x| x.destroy_self_and_children(child_funcs) }
  end

  # def max_by
  #   # Why three values in tuple that we call max() on ?
  #   # To deterministically break ties.
  #   #
  #   self.map { |v| [yield(v), v.object_id, v] }.max.andand.last
  # end
  # alias :last_by :max_by

  # def min_by
  #   self.map { |v| [yield(v), v.object_id, v] }.min.andand.last
  # end

  alias :first_by :min_by

  def uniq_by
    # Go through the list and select the items we're seeing for the first time
    seen = Hash.new(0)
    self.select { |v| (seen[yield(v)] += 1) == 1 }
  end

  def count_by
    self.inject(Hash.new(0)) { |h, v| h[yield(v)] += 1 ; h }
  end
  
  # from Ruby Cookbook, 
  # http://safari.ibmpressbooks.com/0596523696/rubyckbk-CHP-4-SECT-9
  #
  # sorts low-frequency things to the front, high frequency to the end
  #
  #     [5,4,4,3,3,3,2,2,1].sort_by_frequency
  #  => [1, 5, 2, 2, 4, 4, 3, 3, 3]
  #
  def sort_by_frequency
    histogram = inject(Hash.new(0)) { |hash, x| hash[x] += 1; hash}
    sort_by { |x| [histogram[x], x] }
  end

  # sorts high-frequency things to the front, low frequency to the end, gives count
  #
  #     [500,400,400,300,300,300,200,200,100].sort_by_frequency_with_details
  #  => [[3, 300], [2, 400], [2, 200], [1, 100], [1, 500]]
  #       
  #  in each pair: occurrences first, then item
  #
  def sort_by_frequency_with_details
    histogram = inject(Hash.new(0)) { |hash, x| hash[x] += 1; hash}
    histogram.to_a.map { |arr| [arr[1], arr[0]] }.sort_by {|arr| arr[0]}.reverse
  end

  # Return the items in the enumerable permuted so that when displayed
  # in a table of the desired width, listing the items left to right,
  # the original listing order will be preserved on the vertical axis
  def tabular_rotate(table_width)
    height = ((self.size - 1) / table_width) + 1
    columns = Array.new(height) { Array.new(table_width) }
    self.each_with_index { |e, i| columns[i % height][i / height] = e }
    columns
  end

  # Rails replaced a perfectly fine group_by with one that returns
  # sorted results as an associative array instead... fine, except a 6
  # second group_by ballooned to effectively infinate time
  def group_by
    self.inject(Hash.new { |h, k| h[k] = [] }) { |h, v| h[yield v] << v ; h }
  end

  # Given
  #    [ foo(3), foo(1), foo(2), foo(10),foo(11), foo(22) ]
  # Group
  #    1-3, 10-11, 22-22
  # using eval func passed by block
  #
  # example:
  #    customers = [1,3,20, 21,2].map { |x| Customer[x] }
  #    customers.intervals_by(&:id)
  #    => [ [1,2,3], [20-12] ]
  #
  def intervals_by(options = {})
    # options.allowed_and_required( [:include_inverse], [])
    options.allowed_and_required( [], [])

    ret = []

    # everything that follows depends on input being sorted
    sl = self.map { |x| yield x }
    sl = sl.sort

    # setup; the first interval will CERTAINLY begin w the lowest ordinal item!
    int_b  = int_e = sl.first

    sl.each do |ii|

      if ii != sl.first &&   # don't trigger on the first pass
          ii != int_e + 1    # but aside from that: trigger when new interval started
        ret << [ int_b, int_e ]
        int_b = int_e = ii
      end

      # iterate
      int_e = ii
    end

    # fencepost: make sure the last interval is captured
    ret << [ int_b, int_e ]
    
    ret
  end
    
  # TJIXFIX P3: it would be nice to have a sort!() method

end
