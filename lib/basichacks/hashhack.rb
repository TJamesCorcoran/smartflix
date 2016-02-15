# fix a problem in the Ruby language
# from
#    http://www.faeriemud.org/browser/trunk/lib/fm/utils.rb?format=txt

class Hash
  
  def safe_invert
    new_hash = Hash.new { |hash, key| hash[key] = [] }
    self.keys.each do |kk|
      val = self[kk]
      new_hash[val] << kk
    end
    new_hash
  end
  
  # given
  #   { 1 => [ 10, 20],
  #     2 => [ 10, 30] }
  #
  # generates
  #   { 10 => [1, 2],
  #     20 => [1] ,
  #     30 => [2] }
  #
  def invert_with_array
    new_hash = Hash.new { |hash, key| hash[key] = [] }
    self.keys.each do |kk|
      raise "error" unless self[kk].is_a?(Array)
      self[kk].each do |subval|
        new_hash[subval] << kk
      end
    end
    new_hash
  end
  
  
  # Assumes that all values in hash are commensurable (can be compared), ranks
  # them, and then returns the n keys that give the n largest values, in order
  #
  # E.g.
  #
  # hh = { "a" => 1, "b" => 2, "c" =>3, "d" =>3, "e" => 4 }
  # hh.top_keys(1)
  # > ["e"]
  #
  # hh.top_keys(2)
  # > ["e", "d"]
  #
  # hh.top_keys(3)
  # > ["e", "d", "c"]
  #
  def top_keys(n)
    ret = []
    begin
      count = 0
      inver = self.safe_invert
      inver.keys.sort.reverse.each do |kk|
        inver[kk].each do |val|
          ret << val
          count += 1
          raise "done" if count >= n
        end
      end
    rescue
      # nothing; just a way to jump out 2 levels
    end
    ret
  end
  
  def hash_select(&block)
    select(&block).to_hash
  end
  
  
  # Outputs valid CSS from a hash
  #
  # In: { :font_size => '11px',
  #       :background_color => 'black' }
  #
  # Out: font-size: 11px;
  #      background-color: black;
  #
  def to_styles
    self.inject("") do |styles,p|
      next styles if p[1].nil?
      styles + "#{p[0].to_s.gsub('_','-')}:#{p[1]};"
    end
  end
  
  alias_method :old_index, :[]
  
  def [](start, n = nil)
    return old_index(start) if n.nil?
    selected_keys = keys.sort_by{ |k| k.to_s}[start,n]
    select { |key, val| selected_keys.include?(key) }.to_hash
  end
  
  # Merges hashes of arrays.
  # 
  # For instance:
  #   { :a => [1,2,3] }.deep_merge(:a => [4,5])
  # Yields:
  #   { :a => [1,2,3,4,5] }
  #
  # You can pass a block which will be used to sort the merged arrays.
  
  def sf_deep_merge(other,&block)
    intersect = self.keys & other.keys
    return self.merge(other) if intersect.empty?
    intersect.each do |key|
      self[key] += other.delete(key)
      self[key].sort!(&block) if block
    end
    raise "Something went horribly wrong" if (self.keys & other.keys) != []
    return self.merge(other)
  end
  
  # We find ourselves checking the options passed into funcs all the time.
  # This makes that easier.
  # Call this func on the options hash.  Pass in two arrays: allowed keys, and required keys.
  # Required may be omitted if all allowed keys required 
  # 
  # Usage:
  #
  #    def foo(options = {})
  #         options.allowed_and_required( [:verbose, :debug], [])
  #    end
  # or
  #    def bar(options = {})
  #         options.allowed_and_required( [:infile, verbose, :debug], [:infile])
  #    end
  def allowed_and_required(allowed, required = allowed)
    raise "internal error: specified required keys not a subset of allowed keys" if (required - allowed).any?
    raise "missing required keys: #{(required - self.keys).map{|k| "'#{k}'"}.join(',')}" if (required - self.keys).any?
    raise "unallowed keys present: #{(self.keys - allowed).map{|k| "'#{k}'"}.join(',')}" if (self.keys - allowed).any?
    true
  end
  
end
