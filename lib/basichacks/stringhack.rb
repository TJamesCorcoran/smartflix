# cust-and-paste programming from
#
#    ~/bus/tvr/src/lib_ruby/TvrUtil.rb
#

require 'cgi'

class String

  # Add a linefeed after the desired number of characters, but only at an
  # existing space; multiple arguments for multiple wraps are allowed, and an
  # argument of -1 means repeat the previous argument until the string ends

  def wrap_at(*l)

    return self if (l.size == 0 || l[0] < 0 || self.size <= l[0])

    # Find the last whitespace that's <= l[0] characters in (if present)
    split = rindex(' ', l[0])
    split = index(' ') if (split.nil?)
    return self if (split.nil?)

    # Go recursive if more than one split specified
    left = self[0,split]
    if (l.size == 1)
      right = self[split + 1, self.size - split]
    elsif (l[1] == -1)
      right = self[split + 1, self.size - split].wrap_at(*l)
    else
      right = self[split + 1, self.size - split].wrap_at(*l[1,l.size-1])
    end

    return left + "\n" + right

  end

  # Truncate after the desired number of characters, but only at an
  # existing space
  def truncate_at_word_for_charcount(len)
    return self if self.size <= len
    split = rindex(' ', len)
    split = len if split.nil?
    return self[0,split]
  end

  # Truncate after the desired number of words
  def truncate_at_word_for_wordcount(words)
    self.split(" ")[0,words].join(" ")
  end

  # Extend string class to do SQL quoting

  def quote()
    return Mysql.quote(self)
  end


  # from http://snippets.dzone.com/posts/show/2111
  def self.random_alphanumeric(size=16)
    s = ""
    size.times { s << (i = Kernel.rand(62); i += ((i < 10) ? 48 : ((i < 36) ? 55 : 61 ))).chr }
    s
  end

  def self.random_alphabetic(size=16)
    s = ""
    size.times { s << (i = Kernel.rand(26); i += 97).chr }
    s
  end


   class << self
     alias  rand random_alphanumeric 
     alias  rand random_alphabetic
   end

  
  # like index, but returns the nth occurence
  #   str.index_nth(foo, 0) == str.index(foo)
  def index_nth(pattern, nth)
    (0..nth).inject(0) { |oldstart, new|  ret = self.index(pattern, oldstart); return nil if ret.nil? ; ret + 1 } - 1
  end
  
  def from_index_nth(pattern, nth)
    index = index_nth(pattern, nth)
    return (index.nil? ? nil : self[index .. -1])
  end

  def to_index_nth(pattern, nth)
    index = index_nth(pattern, nth)
    return (index.nil? ? nil : self[0, index])
  end

  def clean_ascii
    self.gsub(/[^\32-\176]/,"")
  end

  # from http://blog.choonkeat.com/weblog/2005/10/10/
  # tweaked by XYZ
  def strip_html

    def inner(text)
      text = text.gsub(/(&nbsp;|\n|\s)+/im, ' ').squeeze(' ').strip.
        gsub(/<([^\s]+)[^>]*(src|href)=\s*(.?)([^>\s]*)\3[^>]*>\4<\/\1>/i, '\4')
      
      text = CGI.unescapeHTML(
                              text.
                              gsub(/<(script|style)[^>]*>.*<\/\1>/im, '').
                              gsub(/<!--.*-->/m, '').
                              gsub(/<hr(| [^>]*)>/i, "___\n").
                              gsub(/<li(| [^>]*)>/i, "\n* ").
                              gsub(/<blockquote(| [^>]*)>/i, '> ').
                              gsub(/<(br)(| [^>]*)>/i, "\n").
                              gsub(/<(\/h[\d]+|p)(| [^>]*)>/i, "\n\n").
                              gsub(/<[^>]*>/, '')
                              ).lstrip.gsub(/\n[ ]+/, "\n") # + "\n"
      text
    end

    # is two passes enough?  I'm pretty sure that it is.
    inner(inner(self))
  end
  
  def strip_unprintable
    self.gsub(/[^ [:graph:]]/, " ")
  end

  def contains_unprintable
    self.match(/[^ [:graph:]]/) 
  end

  
  def empty_is_nil
    self.match(/^\s*$/) ? nil : self
  end

  def latex_escape
    escaped = String.new(self )
    escaped.gsub!(/\n/, "\\\\\\\\")
    escaped.gsub!(/#/,  "\\#") 
    escaped.gsub!(/&/,  "\\\\&")  # yes, we seem to need 4 slashes.  WT* ?
    escaped.gsub!(/_/,  "\\_") 
    escaped.gsub!(/%/,  "\\%") 
    escaped.gsub!(/\{/, "\\{") 
    escaped.gsub!(/\}/, "\\}") 
    escaped.gsub!(/\$/, "\\$") 
    escaped
  end

  def regexp_escape
    Regexp.escape(self)
  end
  
  # Summarizes a passage of text by cutting it off at the last word boundary
  # before -len-
  def summarize(len)
    if self.size <= len
      summary = self
    else
      split = self.rindex(' ', len)
      split = len if split.nil?
      summary = self[0,split]
      summary << "..."
    end
    summary
  end

  def self.is_char_alpha(char)
    raise "not a char" if char.size != 1 
    ! "ABCDEFGHIJKLMNOPQRSTUVWXYZ".index(char.upcase).nil?
  end
  
  def self.is_char_numer(char)
    raise "not a char" if char.size != 1 
    ! "0123456789".index(char).nil?
  end
  
  def is_all_alpha
    self.split(//).detect { |char| ! String.is_char_alpha(char)}.nil?
  end

  def is_all_numer
    self.split(//).detect { |char| ! String.is_char_numer(char)}.nil?
  end

  def pluralize_conditional(count)
    count == 1 ? self : self.pluralize
  end

  # "foo", 0  --> "0 foos"
  # "foo", 1  --> "1 foo"
  # "foo", 2  --> "2 foos"
  def number_and_plural(count)
    single_or_plural = (count == 1 ? self : self.pluralize)
    "#{count} #{single_or_plural}"
  end

  def self.plural_choice(count, singular_word, plural_word)
    count.size == 1 ? singular_word : plural_word
  end


  # singularize was designed to work on nouns, but not all of our cat names are nouns
  alias_method :old_singularize, :singularize
  def singularize
    self.downcase.match(/(brass|preparedness|wellness|business|glass|bass)$/) ? self : self.old_singularize
  end

  def to_date
    Date.parse(self)
  end
  
  def to_datetime
    DateTime.parse(self)
  end

  
  # In some places (like
  # tvr-master/app/controllers/stats_controller.rb) we want to take
  # arbitrary human strings and turn them into symbols...symbols that
  # might also be used as element ids in HTML, and referenced DOM
  # elements in Javascript.  Therefore, we need to really clean up the
  # text and generate a symbol that's useful in these circumstances.
  def to_sym_clean()
    self.gsub(/[^a-zA-Z0-9]/, "").downcase.to_sym
  end

  def to_ii
    if self.match(/thousand/) 
      return((self.to_f * 1000).to_i)
    elsif self.match(/million/) 
      return((self.to_f * 1000 * 1000).to_i)
    elsif self.match(/billion/) 
      return((self.to_f * 1000 * 1000 * 1000).to_i)
    elsif self.match(/trillion/) 
      return((self.to_f * 1000 * 1000 * 1000  * 1000 ).to_i)
    end
    
  end

  def url?
    match(/^http/).to_bool
  end
  def domain
    return nil unless url?
    match(/http.*:\/\/([^\/]*)\//)
    $1
  end

  def indent_with_spaces(n = 2)
    self.gsub(/^ */, (" " *n))
  end

  SOUNDEX_ALPHA_MAP = { 'a' => nil, 'b' => '1', 'c' => '2', 'd' => '3', 'e' => nil, 'f' => '1',
                        'g' => '2', 'h' => nil, 'i' => nil, 'j' => '2', 'k' => '2', 'l' => '4',
                        'm' => '5', 'n' => '5', 'o' => nil, 'p' => '1', 'q' => '2', 'r' => '6',
                        's' => '2', 't' => '3', 'u' => nil, 'v' => '1', 'w' => nil, 'x' => '2',
                        'y' => nil, 'z' => 2, ' ' => nil,  '-' => nil
                      }

  def soundex
    ary = []
    # map all the letters in the supplied name
    self.downcase.each_byte{|ltr| ary.push(SOUNDEX_ALPHA_MAP[ltr.chr])}
    # now drop out repeated values
    ary.length.downto(1){ |idx| ary[idx] = nil if ary[idx]==ary[idx-1] }
    # remove the nil elements
    ary.compact!
    # pad with zeroes
    0.upto(2){ ary.push('0')}
    # Replace the first value with the first letter of the supplied name
    ary[0] = self[0].chr
    # return the first four elements of the array as a string
    return ary[0..3].to_s

  end

  # http://www.truespire.com/2009/05/30/obfuscating-email-addresses-in-ruby-on-rails/
  #
  def obscure
        return nil if self.nil? #Don't bother if the parameter is nil.
        lower = ('a'..'z').to_a
        upper = ('A'..'Z').to_a
        self.split('').map { |char|
            output = lower.index(char) + 97 if lower.include?(char)
            output = upper.index(char) + 65 if upper.include?(char)
            output ? "&##{output};" : (char == '@' ? '&#0064;' : char)
        }.join
  end

  def tex_quote
    # http://stackoverflow.com/questions/1625998/latex-escape-chars
    #
    # There are only 10 special chars: \ { } _ ^ # & $ % ~
    return self.gsub(/([$#_&%{}])/, '\\\\\1')
  end
  
  def remove_between_matched_delims(ss, ee)
    regexp = Regexp.new "#{ss}.*?#{ee}"
    ret = self.gsub(regexp, "")
  end

  def replace_matched_delims(s_old, s_new, e_old, e_new)
    regexp = Regexp.new "#{s_old}(.*?)#{e_old}"
    ret = self.gsub(regexp, "#{s_new}\\1#{e_new}")
  end

end


