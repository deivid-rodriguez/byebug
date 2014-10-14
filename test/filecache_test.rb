require 'byebug/filecache'

module Byebug
  #
  # Tests source file caching in Byebug.
  #
  class FilecacheTest < TestCase
    def setup
      Filecache.clear
    end

    def with_test_file
      File.open(example_path, 'w') { |f| f.write(program) }
      yield
    ensure
      File.delete(example_path)
    end

    def program
      strip_line_numbers <<-EOC
        1:  #
        2:  # Identity method
        3:  #
        4:  def mirror(arg)
        5:    arg
        6:  end
      EOC
    end

    def test_lines_first_time
      with_test_file do
        assert_equal(program, Filecache.lines(example_fullpath).join)
      end
    end

    def test_line
      with_test_file do
        assert_equal("#\n", Filecache.line(example_fullpath, 1))
      end
    end

    def test_line_after_first_time_with_autoreload
      with_test_file do
        assert_equal("# Identity method\n", Filecache.line(example_fullpath, 2))

        change_line(example_fullpath, 2, '# Identity map')

        assert_equal("# Identity map\n", Filecache.line(example_fullpath, 2))
      end
    end

    def test_line_after_first_time_with_noautoreload
      with_test_file do
        assert_equal("# Identity method\n", Filecache.line(example_fullpath, 2))

        change_line(example_fullpath, 2, '# Identity map')

        line = Filecache.line(example_fullpath, 2, false)
        assert_equal("# Identity method\n", line)
      end
    end
  end
end
