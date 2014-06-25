require "huihoo/version"

module HuiHoo

  class Returning < Struct.new(:value, :returning); end

  def self.included(base)
    base.extend ClassMethods
  end

  def returning(value=nil)
    throw :hook_stop, Returning.new(value, true)
  end

  def halt
    throw :hook_stop, Returning.new(value, false)
  end

  def hookable(method)
    ret = catch(:hook_stop) { self.run_hooks(:before, method) }
    return ret.value if ret.is_a?(Returning) && ret.returning

    value = yield

    ret = catch(:hook_stop) { self.run_hooks(:after, method) }
    ret.is_a?(Returning) && ret.returning ? ret.value : value
  end

  def run_hooks(before_or_after, met)
    self.class.hooks[met][before_or_after].each {|c|
      if Symbol === c
        method(c).call
      else
        c.call(self)
      end
    }
    false
  end

  module ClassMethods

    def before(method, callback=nil, &block)
      hooks[method][:before] << (callback or block)
    end

    def after(method, callback=nil, &block)
      hooks[method][:after] << (callback or block)
    end

    def hooks
      @__hooks ||= Hash.new {|h, k| h[k] = {:before => [], :after => []} }
    end
  end
end



