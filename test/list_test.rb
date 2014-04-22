module ListTest
  class ListTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 6
        a = 7
        a = 8
        a = 9
        a = 10
        a = 11
        a = 12
        a = 13
        a = 14
        a = 15
        a = 16
        a = 17
        a = 18
        a = 19
        a = 20
        a = 21
        a = 22
        a = 23
        a = 24
        a = 25
        a = '%26'
      end
    end

    def lines_between(min, max, mark_current = true)
      lines = [*File.open(__FILE__)][min-1..max-1]
      numbers = (min..max).to_a
      output = numbers.zip(lines).map { |l| sprintf("%2d: %s", l[0], l[1]) }
      if mark_current
        middle = (output.size/2.0).ceil
        output[middle] = "=> #{output[middle]}"
      end
      output
    end

    describe 'listsize' do
      it 'must show lines according to :listsize setting' do
        debug_proc(@example)
        check_output_includes "[1, 10] in #{__FILE__}"
      end

      it 'must not set it if the param is not an integer' do
        enter 'set listsize 4.0', 'list'
        debug_proc(@example)
        check_output_includes "[1, 10] in #{__FILE__}"
      end

      describe 'when it goes before beginning of file' do
        temporary_change_hash Byebug::Setting, :listsize, 12

        it 'must move range up' do
          enter 'list'
          debug_proc(@example)
          check_output_includes "[1, 12] in #{__FILE__}"
        end
      end

      describe 'when it goes after the end of file' do
        it 'must move range down' do
          skip "Can't test this with the current setup"
        end
      end

      describe 'very large' do
        temporary_change_hash Byebug::Setting, :listsize, 1000

        it 'must list whole file if number of lines is smaller than listsize' do
          n_lines = %x{wc -l #{__FILE__}}.split.first.to_i
          debug_proc(@example)
          check_output_includes "[1, #{n_lines}] in #{__FILE__}"
        end
     end
    end

    describe 'without arguments' do
      it 'must show surrounding lines with the first call' do
        enter 'break 8', 'cont'
        debug_proc(@example)
        check_output_includes("[3, 12] in #{__FILE__}", *lines_between(3, 12))
      end

      it 'must list forward after second call' do
        enter 'break 8', 'cont', 'list'
        debug_proc(@example)
        check_output_includes("[13, 22] in #{__FILE__}",
                              *lines_between(13, 22, false))
      end
    end

    describe 'list backwards' do
      temporary_change_hash Byebug::Setting, :autolist, false

      it 'must show surrounding lines with the first call' do
        enter 'break 18', 'cont', 'list -'
        debug_proc(@example)
        check_output_includes("[13, 22] in #{__FILE__}", *lines_between(13, 22))
      end

      it 'must list backward after second call' do
        enter 'break 18', 'cont', 'list -', 'list -'
        debug_proc(@example)
        check_output_includes("[3, 12] in #{__FILE__}",
                              *lines_between(3, 12, false))
      end
    end

    describe 'list surrounding' do
      temporary_change_hash Byebug::Setting, :autolist, false

      it 'must show the surrounding lines with =' do
        enter 'break 8', 'cont', 'list ='
        debug_proc(@example)
        check_output_includes("[3, 12] in #{__FILE__}", *lines_between(3, 12))
      end
    end

    describe 'specific range' do
      it 'must show with mm-nn' do
        enter 'list 7-9'
        debug_proc(@example)
        check_output_includes("[7, 9] in #{__FILE__}",
                              *lines_between(7, 9, false))
      end

      it 'must show with mm,nn' do
        enter 'list 7,9'
        debug_proc(@example)
        check_output_includes("[7, 9] in #{__FILE__}",
                              *lines_between(7, 9, false))
      end

      it 'must show nothing if there is no such lines' do
        enter 'list 500,505'
        debug_proc(@example)
        check_error_includes 'Invalid line range'
        check_output_doesnt_include "[500, 505] in #{__FILE__}"
        check_output_doesnt_include(/^500  \S/)
      end

      it 'must show nothing if range is incorrect' do
        enter 'list 5,4'
        debug_proc(@example)
        check_output_includes "[5, 4] in #{__FILE__}"
      end
    end

    describe 'arround specific line' do
      it 'must show surroundings with mm-' do
        enter 'list 17-'
        debug_proc(@example)
        check_output_includes("[12, 21] in #{__FILE__}",
                              *lines_between(12, 21, false))
      end

      it 'must show surroundings with mm,' do
        enter 'list 17,'
        debug_proc(@example)
        check_output_includes("[12, 21] in #{__FILE__}",
                              *lines_between(12, 21, false))
      end
    end

    describe 'reload source' do
      after  { change_line_in_file(__FILE__, 7, '        a = 7')   }

      describe 'when autoreload is false' do
        temporary_change_hash Byebug::Setting, :autoreload, false

        it 'must not reload listing with file changes' do
          enter -> { change_line_in_file __FILE__, 7, '        a = 100' ;
                     'list 7-7' }
          debug_proc(@example)
          check_output_includes(/7:\s+a = 7/)
        end
      end

      describe 'when autoreload is true' do
        it 'must reload listing with file changes' do
          enter -> { change_line_in_file __FILE__, 7, '        a = 100' ;
                     'list 7-7' }
          debug_proc(@example)
          check_output_includes(/7:\s+a = 100/)
        end
      end
    end

    it 'must show an error when there is no such file' do
      enter -> { state.file = 'blabla'; 'list 7-7' }
      debug_proc(@example)
      check_error_includes 'No sourcefile available for blabla'
    end

    it 'must correctly print lines containing % sign' do
      enter 'list 26'
      debug_proc(@example)
      check_output_includes "26:         a = '%26'"
    end
  end
end
