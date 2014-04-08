ex = BreakpointDeepExample.new.a
2.times do
  ex = ex ? ex : 1
end
