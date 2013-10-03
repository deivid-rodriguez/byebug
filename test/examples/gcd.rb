# Greatest common divisor of a and b
def gcd a, b
  x = [a,b].max
  y = [a,b].min

  while y != 0
    r = x % y
    x = y
    y = r
  end

  x
end

puts gcd ARGV[0].to_i, ARGV[1].to_i
