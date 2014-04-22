module MethodTest
  class Example
    def initialize
      @a = 'b'
      @c = 'd'
    end
    def self.foo
      "asdf"
    end
    def bla
      "asdf"
    end
  end

  class MethodTestCase < TestDsl::TestCase
    before do
      Byebug::Setting[:autolist] = false
      @example = -> do
        byebug
        a = Example.new
        a.bla
      end
    end

    after do
      Byebug::Setting[:autolist] = true
    end

    describe 'show instance method of a class' do
      before { enter 'break 4', 'cont' }

      it 'must show using full command name' do
        enter 'method Example'
        debug_proc(@example)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end

      it 'must show using shortcut' do
        enter 'm Example'
        debug_proc(@example)
        check_output_includes(/bla/)
      end

      it 'must show an error if specified object is not a class or module' do
        enter 'm a'
        debug_proc(@example)
        check_output_includes 'Should be Class/Module: a'
      end
    end

    describe 'show methods of an object' do
      before { enter 'break 21', 'cont' }

      it 'must show using full command name' do
        enter 'method instance a'
        debug_proc(@example)
        check_output_includes(/bla/)
        check_output_doesnt_include(/foo/)
      end

      it 'must show using shortcut' do
        enter 'm i a'
        debug_proc(@example)
        check_output_includes(/bla/)
      end
    end

    describe 'show instance variables of an object' do
      before { enter 'break 21', 'cont' }

      it 'must show using full name command' do
        enter 'method iv a'
        debug_proc(@example)
        check_output_includes '@a = "b"', '@c = "d"'
      end

      it 'must show using shortcut' do
        enter 'm iv a'
        debug_proc(@example)
        check_output_includes '@a = "b"', '@c = "d"'
      end
    end
  end
end
