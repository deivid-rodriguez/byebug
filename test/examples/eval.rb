byebug

b = 5
c = b + 5
c

class EvalTest
  def inspect
    raise "Broken"
  end
end

@foo = EvalTest.new
b = 6
