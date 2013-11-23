class VariablesExample
  SOMECONST = 'foo' unless defined?(SOMECONST)

  def initialize
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

class TestVariables < TestDsl::TestCase
  describe 'class variables' do
    before { enter "break #{__FILE__}:17", 'cont' }

    it 'must show variables' do
      enter 'var class'
      debug_file 'variables'
      check_output_includes '@@class_c = 3'
    end

    it 'must be able to use shortcut' do
      enter 'v cl'
      debug_file 'variables'
      check_output_includes '@@class_c = 3'
    end
  end

  describe 'constants' do
    it 'must show constants' do
      enter 'break 4', 'cont', 'var const VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST => "foo"'
    end

    it 'must be able to use shortcut' do
      enter 'break 4', 'cont', 'v co VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST => "foo"'
    end

    it 'must show error message if given object is not a class or a module' do
      enter 'break 4', 'cont', 'var const v'
      debug_file 'variables'
      check_output_includes 'Should be Class/Module: v'
    end
  end

  describe 'globals' do
    it 'must show global variables' do
      enter 'break 4', 'cont', 'var global'
      debug_file 'variables'
      check_output_includes '$VERBOSE = true'
    end

    it 'must be able to use shortcut' do
      enter 'break 4', 'cont', 'v g'
      debug_file 'variables'
      check_output_includes '$VERBOSE = true'
    end
  end

  describe 'instance variables' do
    it 'must show instance variables of the given object' do
      enter 'break 4', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes '@inst_a = 1', '@inst_b = 2'
    end

    it 'must show instance variables of self' do
      enter "break #{__FILE__}:9", 'cont', 'var instance'
      debug_file 'variables'
      check_output_includes '@inst_a = 1', '@inst_b = 2'
    end

    it 'must show instance variables' do
      enter 'break 4', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes '@inst_a = 1', '@inst_b = 2'
    end

    it 'must be able to use shortcut' do
      enter 'break 4', 'cont', 'v ins v'
      debug_file 'variables'
      check_output_includes '@inst_a = 1', '@inst_b = 2'
    end

    describe 'when width is too small' do
      temporary_change_hash Byebug.settings, :width, 20

      it 'must cut long variable values according it' do
        enter 'break 4', 'cont', 'var instance v'
        debug_file 'variables'
        check_output_includes '@inst_c = "1111111111111111...'
      end
    end

    it 'must show error if value doesn\'t have #to_s/#inspect methods' do
      enter 'break 4', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes '@inst_d = *Error in evaluation*'
    end
  end

  describe 'local variables' do
    it 'must show local variables' do
      enter "break #{__FILE__}:15", 'cont', 'var local'
      debug_file 'variables'
      check_output_includes 'a => 4', 'b => nil', 'i => 1'
    end
  end

  describe 'test for "var ct" command' do
    it 'must work' do
      skip('can\'t install ruby-internal gem')
    end
  end
end
