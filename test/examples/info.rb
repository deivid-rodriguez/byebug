byebug
def bla(a, b)
  a + b
end
2
3
4
5
6
bla("a" * 30, "b")

class A
  def initialize
    @foo = "bar"
    @bla = "blabla"
  end

  def a
    a = "1" * 30
    b = 2
    @foo
  end

  def c
    a = BasicObject.new
    a
  end

  def b
    a
    e = "%.2f"
    e
  end
end

A.new.b
A.new.a
A.new.c
