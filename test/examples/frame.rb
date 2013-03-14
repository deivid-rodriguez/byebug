byebug

class A
  def a
    b
  end
  def b
    c
    2
  end
  def c
    d('a')
    3
  end
  def d(e)
    5
  end
end

A.new.a
