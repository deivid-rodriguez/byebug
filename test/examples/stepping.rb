byebug

ex = SteppingExample.a(7)
2.times do
  ex += 1
end

SteppingExample.b(ex)
