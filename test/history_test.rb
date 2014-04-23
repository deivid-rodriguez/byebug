module HistoryTest
  class HistoryTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
      end
    end

    describe 'history command' do
      temporary_change_const Readline, 'HISTORY', %w(aaa bbb ccc ddd)

      describe 'with autosave disabled' do
        temporary_change_hash Byebug::Setting, :autosave, false

        it 'must not show records from readline' do
          enter 'history'
          debug_proc(@example)
          check_error_includes "Not currently saving history. " \
                               'Enable it with "set autosave"'
        end
      end

      describe 'with autosave enabled' do
        temporary_change_hash Byebug::Setting, :autosave, true

        describe 'must show records from readline' do
          it 'displays last max_size records from readline history' do
            enter 'set histsize 3', 'history'
            debug_proc(@example)
            check_output_includes(/2  bbb\n    3  ccc\n    4  ddd/)
            check_output_doesnt_include(/1  aaa/)
          end
        end

        describe 'max records' do
          it 'displays whole history if max_size is bigger than Readline::HISTORY' do
            enter 'set histsize 7', 'history'
            debug_proc(@example)
            check_output_includes(/1  aaa\n    2  bbb\n    3  ccc\n    4  ddd/)
          end
        end

        describe 'with specified size' do
          it 'displays the specified number of entries most recent first' do
            enter 'history 2'
            debug_proc(@example)
            check_output_includes(/3  ccc\n    4  ddd/)
            check_output_doesnt_include(/1  aaa\n    2  bbb/)
          end
        end
      end
    end
  end
end
