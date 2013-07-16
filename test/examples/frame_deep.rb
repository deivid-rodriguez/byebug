class FrameDeepExample
  def a
    z = 1
    z += b
  end
  def b
    z = 2
    z += c
  end
  def c
    z = 3
    byebug
    z += d('a')
  end
  def d(e)
    z = 4
  end
end

FrameDeepExample.new.a
