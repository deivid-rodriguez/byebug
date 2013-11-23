class EvalTest
  def sum(a,b)
    a + b
  end

  def inspect
    raise "Broken"
  end
end

class TestEval < TestDsl::TestCase
  it 'must evaluate an expression' do
    enter 'eval 3 + 2'
    debug_file 'eval'
    check_output_includes '5'
  end

  it 'must work with shortcut' do
    enter 'e 3 + 2'
    debug_file 'eval'
    check_output_includes '5'
  end

  it 'must work with another syntax' do
    enter 'p 3 + 2'
    debug_file 'eval'
    check_output_includes '5'
  end

  it 'must work when inspect raises an exception' do
    enter 'c 4', 'p @foo'
    debug_file('eval') { state.line.must_equal 4 }
    check_output_includes 'RuntimeError Exception: Broken'
  end

  describe 'autoeval' do
    it 'must be set by default' do
      enter '[5,6,7].inject(&:+)'
      debug_file 'eval'
      check_output_includes '18'
    end

    it 'can be turned off and back on' do
      enter 'set noautoeval', '[5,6,7].inject(&:+)',
            'set autoeval',   '[1,2,3].inject(&:+)'
      debug_file 'eval'
      check_output_doesnt_include '18'
      check_output_includes '6'
    end
  end

  describe 'stack trace on error' do
    describe 'when enabled' do
      temporary_change_hash Byebug.settings, :stack_on_error, true

      it 'must show a stack trace' do
        enter 'eval 2 / 0'
        debug_file 'eval'
        check_output_includes(/\s*from \S+:in \`eval\'/)
        check_output_doesnt_include 'ZeroDivisionError Exception: divided by 0'
      end
    end

    describe 'when disabled' do
      temporary_change_hash Byebug.settings, :stack_on_error, false

      it 'must only show exception' do
        enter 'eval 2 / 0'
        debug_file 'eval'
        check_output_includes 'ZeroDivisionError Exception: divided by 0'
        check_output_doesnt_include(/\S+:\d+:in `eval':divided by 0/)
      end
    end
  end

  describe 'pp' do
    it 'must pretty print the expression result' do
      enter 'pp {a: \'3\' * 40, b: \'4\' * 30}'
      debug_file 'eval'
      check_output_includes "{:a=>\"#{'3' * 40}\",\n :b=>\"#{'4' * 30}\"}"
    end
  end

  describe 'putl' do
    temporary_change_hash Byebug.settings, :width, 20

    it 'must print expression and columnize the result' do
      enter 'putl [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_file 'eval'
      check_output_includes "1  3  5  8  6\n2  4  9  7"
    end
  end

  describe 'ps' do
    temporary_change_hash Byebug.settings, :width, 20

    it 'must print expression and sort and columnize the result' do
      enter 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_file 'eval'
      check_output_includes "1  3  5  7  9\n2  4  6  8"
    end
  end
end
