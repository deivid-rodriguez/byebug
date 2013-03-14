byebug
class MethodEx
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
a = MethodEx.new
a
