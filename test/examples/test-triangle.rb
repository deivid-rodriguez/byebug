require 'minitest/autorun'
require_relative 'triangle.rb'

class TestTri < MiniTest::Unit::TestCase
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
