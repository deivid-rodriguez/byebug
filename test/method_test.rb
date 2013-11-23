class MethodExample
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

class TestMethod < TestDsl::TestCase
  temporary_change_hash Byebug.settings, :autolist, 0

  describe 'show instance method of a class' do
    before { enter 'break 4', 'cont' }

    it 'must show using full command name' do
      enter 'method MethodExample'
      debug_file 'method'
      check_output_includes(/bla/)
      check_output_doesnt_include(/foo/)
    end

    it 'must show using shortcut' do
      enter 'm MethodExample'
      debug_file 'method'
      check_output_includes(/bla/)
    end

    it 'must show an error if specified object is not a class or module' do
      enter 'm a'
      debug_file 'method'
      check_output_includes 'Should be Class/Module: a'
    end
  end

  describe 'show methods of an object' do
    before { enter 'break 4', 'cont' }

    it 'must show using full command name' do
      enter 'method instance a'
      debug_file 'method'
      check_output_includes(/bla/)
      check_output_doesnt_include(/foo/)
    end

    it 'must show using shortcut' do
      enter 'm i a'
      debug_file 'method'
      check_output_includes(/bla/)
    end
  end

  describe 'show signature of a method' do
    it 'must work' do
      skip('TODO, can\'t install ruby-internal gem')
    end
  end

  describe 'show instance variables of an object' do
    before { enter 'break 4', 'cont' }

    it 'must show using full name command' do
      enter 'method iv a'
      debug_file 'method'
      check_output_includes '@a = "b"', '@c = "d"'
    end

    it 'must show using shortcut' do
      enter 'm iv a'
      debug_file 'method'
      check_output_includes '@a = "b"', '@c = "d"'
    end
  end
end
