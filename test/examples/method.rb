byebug
class MethodExample
  def initialize
    @a = 'b'
    @c = 'd'
  end
  def self.foo
    "asdf"
  end
  def bla
    "asdf"
  end
end
a = MethodExample.new
a
