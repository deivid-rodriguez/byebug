module VariablesTest
  class Example
    SOMECONST = 'foo' unless defined?(SOMECONST)

    def initialize
      @inst_a = 1
      @inst_b = 2
      @inst_c = "1" * 40
      @inst_d = BasicObject.new
    end

    def run
      a = 4
      b = [1, 2, 3].map do |i|
        a * i
      end
      b
    end
  end


  class VariablesTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug

        v = Example.new
        v.run
      end
    end

    # we check a class minitest variable... brittle but ok for now
    describe 'class variables' do
      before { enter 'break 28', 'cont' }

      it 'must show variables' do
        enter 'var class'
        debug_proc(@example)
        check_output_includes(/@@runnables/)
      end

      it 'must be able to use shortcut' do
        enter 'v cl'
        debug_proc(@example)
        check_output_includes(/@@runnables/)
      end
    end

    describe 'constants' do
      it 'must show constants' do
        enter 'break 28', 'cont', 'var const Example'
        debug_proc(@example)
        check_output_includes 'SOMECONST => "foo"'
      end

      it 'must be able to use shortcut' do
        enter 'break 28', 'cont', 'v co Example'
        debug_proc(@example)
        check_output_includes 'SOMECONST => "foo"'
      end

      it 'must show error message if given object is not a class or a module' do
        enter 'break 28', 'cont', 'var const v'
        debug_proc(@example)
        check_output_includes 'Should be Class/Module: v'
      end
    end

    describe 'globals' do
      it 'must show global variables' do
        enter 'break 28', 'cont', 'var global'
        debug_proc(@example)
        check_output_includes '$VERBOSE = true'
      end

      it 'must be able to use shortcut' do
        enter 'break 28', 'cont', 'v g'
        debug_proc(@example)
        check_output_includes '$VERBOSE = true'
      end
    end

    describe 'instance variables' do
      it 'must show instance variables of the given object' do
        enter 'break 28', 'cont', 'var instance v'
        debug_proc(@example)
        check_output_includes '@inst_a = 1', '@inst_b = 2'
      end

      it 'must show instance variables of self' do
        enter 'break 9', 'cont', 'var instance'
        debug_proc(@example)
        check_output_includes '@inst_a = 1', '@inst_b = 2'
      end

      it 'must show instance variables' do
        enter 'break 28', 'cont', 'var instance v'
        debug_proc(@example)
        check_output_includes '@inst_a = 1', '@inst_b = 2'
      end

      it 'must be able to use shortcut' do
        enter 'break 28', 'cont', 'v ins v'
        debug_proc(@example)
        check_output_includes '@inst_a = 1', '@inst_b = 2'
      end

      describe 'when width is too small' do
        temporary_change_hash Byebug::Setting, :width, 20

        it 'must cut long variable values according it' do
          enter 'break 28', 'cont', 'var instance v'
          debug_proc(@example)
          check_output_includes '@inst_c = "1111111111111111...'
        end
      end

      it 'must show error if value doesn\'t have #to_s/#inspect methods' do
        enter 'break 28', 'cont', 'var instance v'
        debug_proc(@example)
        check_output_includes '@inst_d = *Error in evaluation*'
      end
    end

    describe 'local variables' do
      it 'must show local variables' do
        enter 'break 15', 'cont', 'var local'
        debug_proc(@example)
        check_output_includes 'a => 4', 'b => nil', 'i => 1'
      end
    end
  end
end
