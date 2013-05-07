require_relative 'test_helper'

describe 'Source Command' do
  include TestDsl

  let(:filename) { 'source_example.txt' }

  def after_setup
    File.open(filename, 'w') do |f|
      f.puts 'break 2'
      f.puts 'break 3 if true'
    end
  end

  def before_teardown
    FileUtils.rm(filename)
  end

  it 'must run commands from file' do
    enter "source #{filename}"
    debug_file 'source' do
      Byebug.breakpoints[0].pos.must_equal 2
      Byebug.breakpoints[1].pos.must_equal 3
      Byebug.breakpoints[1].expr.must_equal 'true'
    end
  end

  it 'must be able to use shortcut' do
    enter "so #{filename}"
    debug_file('source') { Byebug.breakpoints[0].pos.must_equal 2 }
  end

  it 'must show an error if file is not found' do
    enter 'source blabla'
    debug_file 'source'
    check_output_includes /File ".*blabla" not found/, interface.error_queue
  end

  describe 'Help' do
    it 'must show help when used without arguments' do
      enter 'source'
      debug_file 'source'
      check_output_includes \
        "source FILE\texecutes a file containing byebug commands"
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      enter 'cont', "so #{filename}"
      debug_file('post_mortem') { Byebug.breakpoints[0].pos.must_equal 3 }
    end
  end
end
