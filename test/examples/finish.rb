byebug

class FinishExample
  def a
    b
  end
  def b
    c
    2
  end
  def c
    d
    3
  end
  def d
    5
  end
end

FinishExample.new.a
