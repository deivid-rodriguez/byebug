require_relative 'test_helper'

describe 'Eval Command' do
  include TestDsl

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
    it 'must show a stack trace if showing trace on error is enabled' do
      enter 'set notrace', 'eval 2 / 0'
      debug_file 'eval'
      check_output_includes 'ZeroDivisionError Exception: divided by 0'
      check_output_doesnt_include /\S+:\d+:in `eval':divided by 0/
    end

    it 'must show a stack trace if showing trace on error is enabled' do
      enter 'set trace', 'eval 2 / 0'
      debug_file 'eval'
      check_output_includes /\S+:\d+:in `eval':divided by 0/
      check_output_doesnt_include 'ZeroDivisionError Exception: divided by 0'
    end
  end


  it 'must pretty print the expression result' do
    enter 'pp {a: \'3\' * 40, b: \'4\' * 30}'
    debug_file 'eval'
    check_output_includes "{:a=>\"#{'3' * 40}\",\n :b=>\"#{'4' * 30}\"}"
  end

  it 'must print expression and columnize the result' do
    temporary_change_hash_value(Byebug::PutLCommand.settings, :width, 20) do
      enter 'putl [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_file 'eval'
      check_output_includes "1  3  5  8  6\n2  4  9  7"
    end
  end

  it 'must print expression and sort and columnize the result' do
    temporary_change_hash_value(Byebug::PSCommand.settings, :width, 20) do
      enter 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_file 'eval'
      check_output_includes "1  3  5  7  9\n2  4  6  8"
    end
  end

  it 'must set width by the "set" command' do
    temporary_change_hash_value(Byebug::PSCommand.settings, :width, 20) do
      enter 'set width 10', 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
      debug_file 'eval'
      check_output_includes "1  4  7\n2  5  8\n3  6  9"
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      enter 'cont', 'eval 2 + 2'
      debug_file 'post_mortem'
      check_output_includes '4'
    end
  end

end
