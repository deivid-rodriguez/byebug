class TestList < TestDsl::TestCase
  describe 'listsize' do
    it 'must show lines according to :listsize setting' do
      enter 'break 5', 'cont'
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}"
    end

    it 'must not set it if the param is not an integer' do
      enter 'set listsize 4.0', 'break 5', 'cont'
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}"
    end

    it 'must move range up when it goes before begining of file' do
      enter 'break 3', 'cont'
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}"
    end

    it 'must move range down when it goes after end of file' do
      enter 'break 10', 'cont'
      debug_file 'list'
      check_output_includes "[5, 14] in #{fullpath('list')}"
    end

    describe 'very large' do
      temporary_change_hash Byebug.settings, :listsize, 50

      it 'must list whole file if number of lines is smaller than listsize' do
        enter 'break 3', 'cont'
        debug_file 'list'
        check_output_includes "[1, 23] in #{fullpath('list')}"
      end
   end
  end

  describe 'without arguments' do
    it 'must show surrounding lines with the first call' do
      enter 'break 5', 'cont'
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}", '1: byebug',
        '2: a = 2', '3: a = 3', '4: a = 4', '=>  5: a = 5', '6: a = 6',
        '7: a = 7', '8: a = 8', '9: a = 9', '10: a = 10'
    end

    it 'must list forward after second call' do
      enter 'break 5', 'cont', 'list'
      debug_file 'list'
      check_output_includes "[11, 20] in #{fullpath('list')}", '11: a = 11',
        '12: a = 12', '13: a = 13', '14: a = 14', '15: a = 15', '16: a = 16',
        '17: a = 17', '18: a = 18', '19: a = 19', '20: a = 20'
    end
  end

  describe 'list backwards' do
    temporary_change_hash Byebug.settings, :autolist, 0

    it 'must show surrounding lines with the first call' do
      enter 'break 15', 'cont', 'list -'
      debug_file 'list'
      check_output_includes "[10, 19] in #{fullpath('list')}", '10: a = 10',
        '11: a = 11', '12: a = 12', '13: a = 13', '14: a = 14', '=> 15: a = 15',
        '16: a = 16', '17: a = 17', '18: a = 18', '19: a = 19'
    end

    it 'must list backward after second call' do
      enter 'break 15', 'cont', 'list -', 'list -'
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}", '1: byebug',
        '2: a = 2', '3: a = 3', '4: a = 4', '5: a = 5', '6: a = 6', '7: a = 7',
        '8: a = 8', '9: a = 9', '10: a = 10'
    end
  end

  describe 'list surrounding' do
    temporary_change_hash Byebug.settings, :autolist, 0

    it 'must show the surrounding lines with =' do
      enter 'break 5', 'cont', 'list ='
      debug_file 'list'
      check_output_includes "[1, 10] in #{fullpath('list')}", '1: byebug',
        '2: a = 2', '3: a = 3', '4: a = 4', '=>  5: a = 5', '6: a = 6',
        '7: a = 7', '8: a = 8', '9: a = 9', '10: a = 10'
    end
  end

  describe 'specific range' do
    it 'must show with mm-nn' do
      enter 'list 4-6'
      debug_file 'list'
      check_output_includes \
        "[4, 6] in #{fullpath('list')}", '4: a = 4', '5: a = 5', '6: a = 6'
    end

    it 'must show with mm,nn' do
      enter 'list 4,6'
      debug_file 'list'
      check_output_includes \
        "[4, 6] in #{fullpath('list')}", '4: a = 4', '5: a = 5', '6: a = 6'
    end

    it 'must show nothing if there is no such lines' do
      enter 'list 44,44'
      debug_file 'list'
      check_error_includes 'Invalid line range'
      check_output_doesnt_include "[44, 44] in #{fullpath('list')}"
      check_output_doesnt_include(/^44  \S/)
    end

    it 'must show nothing if range is incorrect' do
      enter 'list 5,4'
      debug_file 'list'
      check_output_includes "[5, 4] in #{fullpath('list')}"
    end
  end

  describe 'arround specific line' do
    it 'must show surroundings with mm-' do
      enter 'list 14-'
      debug_file 'list'
      check_output_includes "[9, 18] in #{fullpath('list')}", '9: a = 9',
        '10: a = 10', '11: a = 11', '12: a = 12', '13: a = 13', '14: a = 14',
        '15: a = 15', '16: a = 16', '17: a = 17', '18: a = 18'
    end

    it 'must show surroundings with mm,' do
      enter 'list 14,'
      debug_file 'list'
      check_output_includes "[9, 18] in #{fullpath('list')}", '9: a = 9',
        '10: a = 10', '11: a = 11', '12: a = 12', '13: a = 13', '14: a = 14',
        '15: a = 15', '16: a = 16', '17: a = 17', '18: a = 18'
    end
  end

  describe 'reload source' do
    after  { change_line_in_file(fullpath('list'), 4, 'a = 4')   }

    describe 'when autoreload is false' do
      temporary_change_hash Byebug.settings, :autoreload, false

      it 'must not reload listing with file changes' do
        enter -> { change_line_in_file fullpath('list'), 4, 'a = 100' ;
                   'list 4-4' }
        debug_file 'list'
        check_output_includes '4: a = 4'
      end
    end

    describe 'when autoreload is true' do
      it 'must reload listing with file changes' do
        enter -> { change_line_in_file fullpath('list'), 4, 'a = 100' ;
                   'list 4-4' }
        debug_file 'list'
        check_output_includes '4: a = 100'
      end
    end
  end

  it 'must show an error when there is no such file' do
    enter -> { state.file = 'blabla'; 'list 4-4' }
    debug_file 'list'
    check_error_includes 'No sourcefile available for blabla'
  end

  it 'must correctly print lines containing % sign' do
    enter 'list 23'
    debug_file 'list'
    check_output_includes "23: a = '%23'"
  end
end
