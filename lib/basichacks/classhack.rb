# add accessors for class variables
# inspiration from
#    http://groups.google.com/group/comp.lang.ruby/browse_thread/thread/9bcf92ddf43e1dc5
class Class
  def class_attr sym
    module_eval "def self.#{sym}() @@#{sym} end"
    module_eval "def self.#{sym}=(x) @@#{sym}=x end"
  end 
end

def class_exists?(class_name)
  klass = Module.const_get(class_name)
  return klass.is_a?(Class)
rescue
  return false
end
