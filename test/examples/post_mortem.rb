byebug

class CatchExample
  def a
    begin
      Byebug.post_mortem do
        z = 4
        raise 'blabla'
        x = 6
      end
    rescue => e
      e
    end
  end
end

c = CatchExample.new
c.a
c