byebug

ex = InterruptExample.a(7)
2.times do
  ex += 1
end

InterruptExample.b(ex)
