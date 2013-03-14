byebug
class VariablesExample
  SOMECONST = 'foo' unless defined?(SOMECONST)

  def initialize
    $glob = 100
    @inst_a = 1
    @inst_b = 2
    @inst_c = "1" * 40
    @inst_d = BasicObject.new
    @@class_c = 3
  end

  def run
    a = 4
    b = [1, 2, 3].map do |i|
      a * i
    end
    b
  end

end

v = VariablesExample.new
v.run
v
