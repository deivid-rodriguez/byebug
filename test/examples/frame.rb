byebug

class FrameExample
  def initialize(f)
    @f = f
  end

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

local_var = "hola"
FrameExample.new('f').a
