#!/usr/bin/env ruby
require "test/unit"
require "tri2.rb"
require "rubygems"
require "ruby-debug"
Byebug.start

class TestTri < Test::Unit::TestCase
  def test_basic
    byebug
    solutions = []
    0.upto(5) do |i|
      solutions << triangle(i)
    end
    assert_equal([0, 1, 3, 6, 10, 15], solutions,
                 "Testing the first 5 triangle numbers")
  end
end
