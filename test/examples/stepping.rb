byebug

class SteppingExample
  def a
    z = 2
    b
  end

  def b
    [1,2,3].map { |a| a.to_f }
    c
  end

  def c
    z = 4
    5
  end
end

ex = SteppingExample.new.a
ex
