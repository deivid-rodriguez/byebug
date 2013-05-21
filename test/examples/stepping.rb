byebug

class SteppingExample
  def a
    z = 2
    b
  end

  def b
    v2 = 5 if 1 == 2 ; [1,2,3].map { |a| a.to_f }
    c
  end

  def c
    z = 4
    5
  end
end

ex = SteppingExample.new.a
2.times do
  ex += 1
end

ex
