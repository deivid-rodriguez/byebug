a = 2
byebug
b = 3
@break1 = false
@break2 = false

t1 = Thread.new do
  until @break1
    sleep 0.02
    @break2 = true
  end
end

until @break2
  sleep 0.02
  @break1 = true
end

t1.join
t1
