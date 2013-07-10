require_relative 'test_helper'

class TestStepping < TestDsl::TestCase

  describe 'Next Command' do

    describe 'Usual mode' do

      describe 'method call behaviour' do
        before { enter 'break 10', 'cont' }

        it 'must leave on the same line by default' do
          enter 'next'
          debug_file('stepping') { $state.line.must_equal 10 }
        end

        it 'must go to the next line if forced by "plus" sign' do
          enter 'next+'
          debug_file('stepping') { $state.line.must_equal 11 }
        end

        it 'must leave on the same line if forced by "minus" sign' do
          enter 'next-'
          debug_file('stepping') { $state.line.must_equal 10 }
        end

        describe 'when force_stepping is set' do
          temporary_change_hash Byebug::Command.settings, :force_stepping, true

          it 'must go to the next line' do
            enter 'next'
            debug_file('stepping') { $state.line.must_equal 11 }
          end

          it 'must go to the next line (by shortcut)' do
            enter 'n'
            debug_file('stepping') { $state.line.must_equal 11 }
          end

          it 'must go the specified number of lines forward by default' do
            enter 'next 2'
            debug_file('stepping') { $state.line.must_equal 21 }
          end

          it 'must ignore it if "minus" is specified' do
            enter 'next-'
            debug_file('stepping') { $state.line.must_equal 10 }
          end
        end
      end

      describe 'block behaviour' do
        before { enter 'break 21', 'cont' }

        it 'must step over blocks' do
          enter 'next'
          debug_file('stepping') { $state.line.must_equal 25 }
        end
      end

    end

    describe 'Post Mortem' do
      temporary_change_hash Byebug::Command.settings, :autoeval, false

      it 'must not work in post-mortem mode' do
        enter 'cont', 'next'
        debug_file 'post_mortem'
        check_output_includes \
          'Unknown command: "next".  Try "help".', interface.error_queue
      end
    end

  end

  describe 'Step Command' do

    describe 'Usual mode' do

      describe 'method call behaviour' do
        before { enter 'break 10', 'cont' }

        it 'must leave on the same line if forced by a setting' do
          enter 'step'
          debug_file('stepping') { $state.line.must_equal 10 }
        end

        it 'must go to the step line if forced to do that by "plus" sign' do
          enter 'step+'
          debug_file('stepping') { $state.line.must_equal 11 }
        end

        it 'must leave on the same line if forced to do that by "minus" sign' do
          enter 'step-'
          debug_file('stepping') { $state.line.must_equal 10 }
        end

        describe 'when force_stepping is set' do
          temporary_change_hash Byebug::Command.settings, :force_stepping, true

          it 'must go to the step line if forced by a setting' do
            enter 'step'
            debug_file('stepping') { $state.line.must_equal 11 }
          end

          it 'must go to the next line if forced by a setting (by shortcut)' do
            enter 's'
            debug_file('stepping') { $state.line.must_equal 11 }
          end

          it 'must go the specified number of lines forward by default' do
            enter 'step 2'
            debug_file('stepping') { $state.line.must_equal 15 }
          end
        end
      end

      describe 'block behaviour' do
        before { enter 'break 21', 'cont' }

        it 'must step into blocks' do
          enter 'step'
          debug_file('stepping') { $state.line.must_equal 22 }
        end
      end
    end

    describe 'Post Mortem' do
      temporary_change_hash Byebug::Command.settings, :autoeval, false

      it 'must not work in post-mortem mode' do
        enter 'cont', 'step'
        debug_file 'post_mortem'
        check_output_includes \
          'Unknown command: "step".  Try "help".', interface.error_queue
      end
    end
  end

end
