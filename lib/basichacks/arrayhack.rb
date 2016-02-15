class Array
  def empty_is_nil
    empty? ? nil : self
  end
  
  
  def to_hash
    Hash[*inject([]) { |array, (key, value)| array + [key, value] }]
  end
  alias :to_h :to_hash
  
  # Divide an array into any number of equal parts.
  #
  # Examples:
  #  [1,2,3].divide(3) #=> [[1],[2],[3]]
  #  [1,2,3,4].divide(3) #=> [[1,2],[3],[4]]
  #  [1,2,3,4,5].divide(3) #=> [[1,2],[3,4],[5]]
  def divide(how_many)
    me = self.dup
    (1..how_many).to_a.reverse.inject([]) do |parts,i|
      part,me = me.break((me.size.to_f / i).ceil)
      parts.push(part)
    end
  end
  
  # "Breaks" an array into two arrays, at a certain index.
  def break(len)
    [self[0,len],self[len..-1]]
  end
  
  # turns [[1,2,3,4], ["a", "b", "c", "d"]]
  # into  [1, "a"], [2, "b"], [3, "c"], [4, "d"]
  def mux
    raise "not implemented yet"
  end
  
  # turns [ [1, "a"], [2, "b"], [3, "c"], [4, "d"]]
  # into [1,2,3,4], ["a", "b", "c", "d"]
  def demux
    x = []
    y = []
    self.each { |inz| raise "wrong size (!= 2) - #{inz.inspect}" if inz.size != 2; x << inz[0] ; y << inz[1] }
    [x,y]
  end
  
  # O(n^2)
  def swap!
    (0 .. size - 1).each do |i|
      (i + 1.. size - 1 ).each do |j|
        self[i], self[j] = self[j], self[i] if yield self[i], self[j]
      end
    end
    self
  end
  
  #  Given two arrays X and Y, generate every pair of x in X, y in Y.
  #
  # > [1,2,3].cross(["a", "b", "c"])
  #
  #  => [[1, "a"], [1, "b"], [1, "c"], [2, "a"], [2, "b"], [2, "c"], [3,"a"], [3, "b"], [3, "c"]]
  #
  # You could imagine this returning an array of hashes ... or you could imagine this function taking a block.
  # Yes, those are cool ideas.  If/when we need them, we can make this more complicated.
  #
  # Also, note that this is not an ideal name.  Cross products and dot products are something different.
  # This is actually a matrix product, I think.
  def cross(array2)
    self.inject([]){ |array, first| array2.inject(array) {|array, second|  array << [first, second]} } 
  end
  
  # first array contains format variants (e.g. ["buy %s tomorrow", "buy %s now])
  # second array contains 
  def cross_format(array2, subtarget, subnew = "%s")
    self.cross(array2).map { |tuple| format tuple[0].gsub(subtarget, subnew), tuple[1]}
  end
  
  # Like each, except passes in two values: the current value, and the previous value.
  # Passes nil as the trailing value of the first item.
  def each_with_trailing
    (0 .. self.size - 1).each { |index| yield self[index], (index == 0 ? nil : self[index - 1] ) }
  end
  
  def each_with_trailing_and_leading
    (0 .. self.size - 1).each { |index| yield self[index], (index == 0 ? nil : self[index - 1] ), (index == self.size ? nil : self[index + 1] ) }
  end
  
  # like map, but ...
  # 
  # [1,2,3].map_with_trailing { |x, trail|  x + trail.to_i }
  #   => [1, 3, 5]
  def map_with_trailing
    (0 .. self.size - 1).map { |index| yield self[index], (index == 0 ? nil : self[index - 1] ) }
  end
  
  
  def average
    self.inject(0) { |sum, x| sum + x } / self.size.to_f
  end
  
  def get_n_around_index(n, index)
    index = self.size + index if index < 0
    self[[index - [n / 2, n - (self.size - index)].max, 0].max, n]
  end
  
  def random_entry
    self[rand(self.size)] 
  end

  # http://snippets.dzone.com/posts/show/1167
  #
  # If 'number' is greater than the size of the array, the method
  # will simply return the array itself sorted randomly
  #
  def random_pick(number)
    sort_by{ rand }.slice(0...number)
  end

  
  # given two arrays of the same size, yield on each pair of entries
  # e.g. [1,2,3].pairwise([10,20,30]) { |x,y| puts "#{x}, #{y}"}
  # ->    1, 10    
  #       2, 20
  #       3, 30
  
  # NOTE: this already exists: the name is ".zip()".
  
  #   def pairwise(array2)
  #     raise "size mismatch" if self.size != array2.size
  #     self.size.times { |ii|        yield self[ii], array2[ii]      }
  #   end

  # given a selector, get a report on the number of instances of each valie
  # 
  # simple example:
  #   [1,2,2,2,2,3].count_by{|x| x}
  #   => {1=>1, 2=>4, 3=>1}
  #
  # more complex:
  #   "my dog is named ocho".split.count_by { |x| x.size }
  #   => {5=>1, 2=>2, 3=>1, 4=>1}
  #
  def count_by(&block)
    self.group_by(&block).map { |pair| [ pair[0], pair[1].size]}.to_h
  end
  
end


module Matrix
  # rotate 90 degrees counter clockwise
  #
  #  [ [ 0, 1 ],        [ [ 1, 3 ],
  #    [ 2, 3 ] ]  -->    [ 0, 2 ]]
  #
  def self.rotate(o)
    rows, cols = o.size, o[0].size
    Array.new(cols){|i| Array.new(rows){|j| o[j][cols - i - 1]}}
  end

  # flip_on_diagonal
  # 
  #  [ [ 0, 1, 2 ],        [ [ 0, 3 ],
  #    [ 3, 4,  5 ] ]  -->   [ 1, 4 ],
  #                          [ 2, 5 ] ]
  def self.flip(o)

    x = o[0].size
    y = o.size
    tmp = Array.new(x) { Array.new }
    x.times { |xi|  y.times { |yi| tmp[xi][yi] = o[yi][xi]      }    } 
    tmp
  end
end
