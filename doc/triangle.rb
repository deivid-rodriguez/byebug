#!/usr/bin/env ruby
# Compute the n'th triangle number - the hard way
# triangle(n) == (n * (n+1)) / 2
def triangle(n)
  tri = 0
  0.upto(n) do |i|
    tri += i
  end
  return tri
 end
 
puts triangle(3)
