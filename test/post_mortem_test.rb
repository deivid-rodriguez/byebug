class PostMortemExample
  def a
    begin
      Byebug.post_mortem do
        z = 4
        raise 'blabla'
        x = 6
        x + z
      end
    rescue => e
      e
    end
  end
end

class TestPostMortem < TestDsl::TestCase
  describe 'Features' do
    before { enter 'cont' }

    it 'must enter into post-mortem mode' do
      debug_file('post_mortem') { Byebug.post_mortem?.must_equal true }
    end

    it 'must stop at the correct line' do
      debug_file('post_mortem') { state.line.must_equal 6 }
    end

    it 'must exit from post-mortem mode after stepping command' do
      enter "break 11", 'cont'
      debug_file('post_mortem') { Byebug.post_mortem?.must_equal false }
    end

    it 'must save the raised exception' do
      debug_file('post_mortem') {
        Byebug.last_exception.must_be_kind_of RuntimeError }
    end
  end

  describe 'Unavailable commands' do
    temporary_change_hash Byebug.settings, :autoeval, false

    describe 'step' do
      it 'must not work in post-mortem mode' do
        enter 'cont', 'step'
        debug_file 'post_mortem'
        check_error_includes 'Unknown command: "step".  Try "help".'
      end
    end

    describe 'next' do
      it 'must not work in post-mortem mode' do
        enter 'cont', 'next'
        debug_file 'post_mortem'
        check_error_includes 'Unknown command: "next".  Try "help".'
      end
    end

    describe 'finish' do
      it 'must not work in post-mortem mode' do
        enter 'cont', 'finish'
        debug_file 'post_mortem'
        check_error_includes 'Unknown command: "finish".  Try "help".'
      end
    end
  end

  describe 'Available commands' do
    before { @tst_file = fullpath('post_mortem') }

    describe 'restart' do
      it 'must work in post-mortem mode' do
        must_restart
        enter 'cont', 'restart'
        debug_file 'post_mortem'
      end
    end

    describe 'display' do
      it 'must be able to set display expressions in post-mortem mode' do
        enter 'cont', 'display 2 + 2'
        debug_file 'post_mortem'
        check_output_includes '1:', '2 + 2 = 4'
      end
    end

    describe 'frame' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'frame'
        debug_file('post_mortem') { state.line.must_equal 6 }
        check_output_includes(
          /--> #0  block in PostMortemExample\.a\s+at #{__FILE__}:6/)
      end
    end

    describe 'condition' do
      it 'must be able to set conditions in post-mortem mode' do
        enter 'cont', "break 11",
              ->{ "cond #{Byebug.breakpoints.first.id} true" }, 'cont'
        debug_file('post_mortem') { state.line.must_equal 11 }
      end
    end

    describe 'break' do
      it 'must be able to set breakpoints in post-mortem mode' do
        enter 'cont', 'break 11', 'cont'
        debug_file('post_mortem') { state.line.must_equal 11 }
      end
    end

    describe 'exit' do
      it 'must work in post-mortem mode' do
        Byebug::QuitCommand.any_instance.expects(:exit!)
        enter 'cont', 'exit!'
        debug_file 'post_mortem'
      end
    end

    describe 'reload' do
      after { change_line_in_file(@tst_file, 4, 'c.a') }

      it 'must work in post-mortem mode' do
        enter 'cont', -> do
          change_line_in_file(@tst_file, 4, 'bo = BasicObject.new')
          'reload'
        end, 'up 3', 'l 4-4'
        debug_file 'post_mortem'
        check_output_includes '=> 4: bo = BasicObject.new'
      end
    end

    describe 'edit' do
      temporary_change_hash ENV, 'EDITOR', 'editr'

      it 'must work in post-mortem mode' do
        Byebug::Edit.any_instance.
                     expects(:system).with("editr +2 #{fullpath('edit')}")
        enter 'cont', "edit #{fullpath('edit')}:2", 'cont'
        debug_file 'post_mortem'
      end
    end

    describe 'info' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'info line'
        debug_file 'post_mortem'
        check_output_includes "Line 6 of \"#{__FILE__}\""
      end
    end

    describe 'irb' do
      let(:irb) { stub(context: ->{}) }

      it 'must work in post-mortem mode' do
        skip "Don't know why this is failing now..."
        irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
        enter 'cont', 'break 11', 'irb'
        debug_file('post_mortem') { state.line.must_equal 11 }
      end
    end

    describe 'source' do
      before { File.open(filename, 'w') do |f|
                 f.puts 'break 2'
                 f.puts 'break 3 if true'
               end }
      after { FileUtils.rm(filename) }

      let(:filename) { 'source_example.txt' }

      it 'must work in post-mortem mode' do
        enter 'cont', "so #{filename}"
        debug_file('post_mortem') { Byebug.breakpoints[0].pos.must_equal 3 }
      end
    end

    describe 'help' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'help'
        debug_file 'post_mortem'
        check_output_includes 'Available commands:'
      end
    end

    describe 'var' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'var local'
        debug_file 'post_mortem'
        check_output_includes 'x => nil', 'z => 4'
      end
    end

    describe 'list' do
      it 'must work in post-mortem mode' do
        enter 'cont'
        debug_file 'post_mortem'
        check_output_includes "[1, 10] in #{__FILE__}"
      end
    end

    describe 'method' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'm i self'
        debug_file 'post_mortem'
        check_output_includes(/to_s/)
      end
    end

    describe 'kill' do
      it 'must work in post-mortem mode' do
        Process.expects(:kill).with('USR1', Process.pid)
        enter 'cont', 'kill USR1'
        debug_file 'post_mortem'
      end
    end

    describe 'eval' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'eval 2 + 2'
        debug_file 'post_mortem'
        check_output_includes '4'
      end
    end

    describe 'set' do
      temporary_change_hash Byebug.settings, :autolist, 0

      it 'must work in post-mortem mode' do
        enter 'cont', 'set autolist on'
        debug_file 'post_mortem'
        check_output_includes 'autolist is on.'
      end
    end

    describe 'save' do
      let(:file_name) { 'save_output.txt' }
      let(:file_contents) { File.read(file_name) }
      after { FileUtils.rm(file_name) }

      it 'must work in post-mortem mode' do
        enter 'cont', "save #{file_name}"
        debug_file 'post_mortem'
        file_contents.must_include 'set autoirb off'
      end
    end

    describe 'show' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'show autolist'
        debug_file 'post_mortem'
        check_output_includes 'autolist is on.'
      end
    end

    describe 'trace' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'trace on'
        debug_file 'post_mortem'
        check_output_includes 'line tracing is on.'
      end
    end

    describe 'thread' do
      it "must work in post-mortem mode" do
        enter 'cont', 'thread list'
        debug_file('post_mortem')
        check_output_includes(/\+ \d+ #<Thread:(\S+) run/)
      end
    end
  end
end
