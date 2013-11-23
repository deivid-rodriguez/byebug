class PostMortemExample
  def a
    z = 4
    raise 'blabla'
    x = 6
    x + z
  end
end

class TestPostMortem < TestDsl::TestCase

  describe 'Features' do
    before { enter 'set post_mortem', 'cont' }

    it 'must enter into post-mortem mode' do
      debug_file('post_mortem', rescue: true) do
        Byebug.post_mortem?.must_equal true
      end
    end

    it 'must stop at the correct line' do
      debug_file('post_mortem', rescue: true) { assert_equal 4, state.line }
    end
  end

  describe 'Unavailable commands' do
    temporary_change_hash Byebug.settings, :autoeval, false

    describe 'step' do
      it 'must not work in post-mortem mode' do
        enter 'set post_mortem', 'cont', 'step'
        debug_file 'post_mortem', rescue: true
        check_error_includes 'Unknown command: "step".  Try "help".'
      end
    end

    describe 'next' do
      it 'must not work in post-mortem mode' do
        enter 'set post_mortem', 'cont', 'next'
        debug_file 'post_mortem', rescue: true
        check_error_includes 'Unknown command: "next".  Try "help".'
      end
    end

    describe 'finish' do
      it 'must not work in post-mortem mode' do
        enter 'set post_mortem', 'cont', 'finish'
        debug_file 'post_mortem', rescue: true
        check_error_includes 'Unknown command: "finish".  Try "help".'
      end
    end

    describe 'break' do
      it 'must not be able to set breakpoints in post-mortem mode' do
        enter 'set post_mortem', 'cont', "break #{__FILE__}:6"
        debug_file 'post_mortem', rescue: true
        check_error_includes "Unknown command: \"break #{__FILE__}:6\".  " \
                             'Try "help".'
      end
    end

    describe 'condition' do
      it 'must not be able to set conditions in post-mortem mode' do
        enter "break #{__FILE__}:6", 'set post_mortem', 'cont',
              ->{ "cond #{Byebug.breakpoints.last.id} true" }
        debug_file 'post_mortem', rescue: true
        check_error_includes \
          "Unknown command: \"cond #{Byebug.breakpoints.last.id} true\".  " \
          "Try \"help\"."
      end
    end

    describe 'display' do
      it 'must be not able to set display expressions in post-mortem mode' do
        enter 'set post_mortem', 'cont', 'display 2 + 2'
        debug_file 'post_mortem', rescue: true
        check_error_includes 'Unknown command: "display 2 + 2".  Try "help".'
      end
    end

    describe 'reload' do
      it 'must work in post-mortem mode' do
        enter 'set post_mortem', 'cont', 'reload'
        debug_file 'post_mortem', rescue: true
        check_error_includes 'Unknown command: "reload".  Try "help".'
      end
    end


  end

  describe 'Available commands' do
    describe 'restart' do
      it 'must work in post-mortem mode' do
        must_restart
        enter 'cont', 'restart'
        debug_file 'post_mortem', rescue: true
      end
    end

    describe 'frame' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'frame'
        debug_file('post_mortem', rescue: true) { state.line.must_equal 4 }
        check_output_includes(/--> #0  PostMortemExample\.a\s+at #{__FILE__}:4/)
      end
    end

    describe 'exit' do
      it 'must work in post-mortem mode' do
        Byebug::QuitCommand.any_instance.expects(:exit!)
        enter 'cont', 'exit!'
        debug_file 'post_mortem', rescue: true
      end
    end

    describe 'edit' do
      temporary_change_hash ENV, 'EDITOR', 'editr'

      it 'must work in post-mortem mode' do
        Byebug::Edit.any_instance.
                     expects(:system).with("editr +2 #{fullpath('edit')}")
        enter 'cont', "edit #{fullpath('edit')}:2", 'cont'
        debug_file 'post_mortem', rescue: true
      end
    end

    describe 'info' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'info line'
        debug_file 'post_mortem', rescue: true
        check_output_includes "Line 4 of \"#{__FILE__}\""
      end
    end

    describe 'irb' do
      let(:irb) { stub(context: ->{}) }

      it 'must work in post-mortem mode' do
        skip "Don't know why this is failing now..."
        irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
        enter 'cont', 'break 11', 'irb'
        debug_file('post_mortem', rescue: true) { state.line.must_equal 11 }
      end
    end

    describe 'source' do
      let(:filename) { 'source_example.txt' }

      before { File.open(filename, 'w') { |f| f.puts 'frame' } }

      it 'must work in post-mortem mode' do
        enter 'cont', "so #{filename}"
        debug_file('post_mortem', rescue: true)
        check_output_includes(/--> #0  PostMortemExample\.a\s+at #{__FILE__}:4/)
      end
    end

    describe 'help' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'help'
        debug_file 'post_mortem', rescue: true
        check_output_includes 'Available commands:'
      end
    end

    describe 'var' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'var local'
        debug_file 'post_mortem', rescue: true
        check_output_includes 'x => nil', 'z => 4'
      end
    end

    describe 'list' do
      it 'must work in post-mortem mode' do
        enter 'cont'
        debug_file 'post_mortem', rescue: true
        check_output_includes "[1, 10] in #{__FILE__}"
      end
    end

    describe 'method' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'm i self'
        debug_file 'post_mortem', rescue: true
        check_output_includes(/to_s/)
      end
    end

    describe 'kill' do
      it 'must work in post-mortem mode' do
        Process.expects(:kill).with('USR1', Process.pid)
        enter 'cont', 'kill USR1'
        debug_file 'post_mortem', rescue: true
      end
    end

    describe 'eval' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'eval 2 + 2'
        debug_file 'post_mortem', rescue: true
        check_output_includes '4'
      end
    end

    describe 'set' do
      temporary_change_hash Byebug.settings, :autolist, 0

      it 'must work in post-mortem mode' do
        enter 'cont', 'set autolist on'
        debug_file 'post_mortem', rescue: true
        check_output_includes 'autolist is on.'
      end
    end

    describe 'save' do
      let(:file_name) { 'save_output.txt' }
      let(:file_contents) { File.read(file_name) }
      after { File.delete(file_name) }

      it 'must work in post-mortem mode' do
        enter 'cont', "save #{file_name}"
        debug_file 'post_mortem', rescue: true
        file_contents.must_include 'set autoirb off'
      end
    end

    describe 'show' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'show autolist'
        debug_file 'post_mortem', rescue: true
        check_output_includes 'autolist is on.'
      end
    end

    describe 'trace' do
      it 'must work in post-mortem mode' do
        enter 'cont', 'trace on'
        debug_file 'post_mortem', rescue: true
        check_output_includes 'line tracing is on.'
      end
    end

    describe 'thread' do
      it "must work in post-mortem mode" do
        enter 'cont', 'thread list'
        debug_file 'post_mortem', rescue: true
        check_output_includes(/\+ \d+ #<Thread:(\S+) run/)
      end
    end
  end
end
