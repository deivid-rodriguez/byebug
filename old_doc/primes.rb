#!/usr/bin/env ruby
# Enumerator for primes
class SievePrime
  @@odd_primes = []
  def self.next_prime(&block)
    candidate = 2
    yield candidate
    not_prime = false
    candidate += 1
    while true do
      @@odd_primes.each do |p|
        not_prime = (0 == (candidate % p))
        break if not_prime
      end
      unless not_prime
        @@odd_primes << candidate
        yield candidate 
      end
      candidate += 2
    end
  end
end
SievePrime.next_prime do |prime|
  puts prime
  break if prime > 10
end

    
