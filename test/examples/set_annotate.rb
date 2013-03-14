byebug

class AnnotateExample
  def a
    @b = 3
    @@c = 4
    d = 5
    e = 6
  end
end

AnnotateExample.new.a
