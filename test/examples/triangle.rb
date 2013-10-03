# Compute the n'th triangle number, the hard way: triangle(n) == (n*(n+1))/2
def triangle(n)
  tri = 0
  0.upto(n) do |i|
    tri += i
  end
  tri
end

if __FILE__ == $0
  t = triangle(3)
  puts t
end
