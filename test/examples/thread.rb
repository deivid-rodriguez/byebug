byebug
class ThreadExample
  def initialize
    Thread.main[:should_break] = false
  end

  def launch
    @t1 = Thread.new do
      while true
        break if Thread.main[:should_break]
        sleep 0.02
      end
    end

    @t2 = Thread.new do
      while true
        sleep 0.02
      end
    end

    @t1.join
    Thread.main[:should_break]
  end

  def kill
    @t2.kill
  end
end

t = ThreadExample.new
t.launch
t.kill
