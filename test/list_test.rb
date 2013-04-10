require_relative 'test_helper'

describe 'List Command' do
  include TestDsl

  describe 'List Command (Setup)' do

    before { LineCache.clear_file_cache }

    describe 'listsize' do
      before do
        Byebug::Command.settings[:listsize] = 3
        Byebug::Command.settings[:autolist] = 0
      end

      it 'must show lines according to :listsize setting' do
        enter 'set listsize 4', 'break 5', 'cont', 'list'
        debug_file 'list'
        check_output_includes "[3, 6] in #{fullpath('list')}"
      end

      it 'must not set it if the param is not an integer' do
        enter 'set listsize 4.0', 'break 5', 'cont', 'list'
        debug_file 'list'
        check_output_includes "[4, 6] in #{fullpath('list')}"
      end

      it 'must move range up when it goes before begining of file' do
        enter 'set listsize 10', 'break 3', 'cont', 'list'
        debug_file 'list'
        check_output_includes "[1, 10] in #{fullpath('list')}"
      end

      it 'must move range down when it goes after end of file' do
        enter 'set listsize 10', 'break 10', 'cont', 'list'
        debug_file 'list'
        check_output_includes "[3, 12] in #{fullpath('list')}"
      end

    end

    describe 'without arguments' do
      before { Byebug::Command.settings[:listsize] = 3 }

      it 'must show surrounding lines with the first call' do
        enter 'break 5', 'cont', 'list'
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '=> 5  5', '6  6'
      end

      it 'must list forward after second call' do
        enter 'break 5', 'cont', 'list', 'list'
        debug_file 'list'
        check_output_includes \
          "[7, 9] in #{fullpath('list')}", '7  7', '8  8', '9  9'
      end
    end

    describe 'list backward' do
      before { Byebug::Command.settings[:listsize] = 3 }

      it 'must show surrounding lines with the first call' do
        enter 'break 5', 'cont', 'list -'
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '=> 5  5', '6  6'
      end

      it 'must list backward after second call' do
        enter 'break 5', 'cont', 'list -', 'list -'
        debug_file 'list'
        check_output_includes \
          "[1, 3] in #{fullpath('list')}", '1  byebug', '2  2', '3  3'
      end
    end


    describe 'list surrounding' do
      before { Byebug::Command.settings[:listsize] = 3 }

      it 'must show the surrounding lines with =' do
        enter 'break 5', 'cont', 'list ='
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '=> 5  5', '6  6'
      end
    end

    describe 'autolist' do
      before { Byebug::Command.settings[:listsize] = 3 }

      it 'must show the surronding lines after stop if autolist is enabled' do
        enter 'set autolist', 'break 5', 'cont'
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '=> 5  5', '6  6'
      end
    end

    describe 'specified lines' do
      before { Byebug::Command.settings[:listsize] = 3 }

      it 'must show with mm-nn' do
        enter 'list 4-6'
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '5  5', '6  6'
      end

      it 'must show with mm,nn' do
        enter 'list 4,6'
        debug_file 'list'
        check_output_includes \
          "[4, 6] in #{fullpath('list')}", '4  4', '5  5', '6  6'
      end

      it 'must show surroundings with mm-' do
        enter 'list 4-'
        debug_file 'list'
        check_output_includes \
          "[3, 5] in #{fullpath('list')}", '3  3', '4  4', '5  5'
      end

      it 'must show surroundings with mm,' do
        enter 'list 4,'
        debug_file 'list'
        check_output_includes \
          "[3, 5] in #{fullpath('list')}", '3  3', '4  4', '5  5'
      end

      it 'must show nothing if there is no such lines' do
        enter 'list 44,44'
        debug_file 'list'
        check_error_includes 'Invalid line range'
        check_output_doesnt_include "[44, 44] in #{fullpath('list')}"
        check_output_doesnt_include /^44  \S/
      end

      it 'must show nothing if range is incorrect' do
        enter 'list 5,4'
        debug_file 'list'
        check_output_includes "[5, 4] in #{fullpath('list')}"
        check_output_doesnt_include '5  5'
        check_output_doesnt_include '4  4'
      end
    end

    describe 'reload source' do
      after do
        change_line_in_file(fullpath('list'), 4, '4')
        Byebug::Command.settings[:reload_source_on_change] = true
      end

      it 'must not reload if setting is false' do
        enter 'set noautoreload', -> do
          change_line_in_file(fullpath('list'), 4, '100')
          'list 4-4'
        end
        debug_file 'list'
        check_output_includes '4  4'
      end

      it 'must reload if setting is true' do
        enter 'set autoreload', -> do
          change_line_in_file(fullpath('list'), 4, '100')
          'list 4-4'
        end
        debug_file 'list'
        check_output_includes '4  100'
      end
    end

    it 'must show an error when there is no such file' do
      enter ->{state.file = 'blabla'; 'list 4-4'}
      debug_file 'list'
      check_output_includes 'No sourcefile available for blabla',
                            interface.error_queue
    end

    describe 'Post Mortem' do
      it 'must work in post-mortem mode' do
        skip('No post morten mode for now')
        enter 'cont', 'list'
        debug_file 'post_mortem'
        check_output_includes "[7, 9] in #{fullpath('post_mortem')}"
      end
    end

  end

end
