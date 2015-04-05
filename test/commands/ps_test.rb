module Byebug
  #
  # Tests ps functionality.
  #
  class PsTestCase < TestCase
    def program
      <<-EOP
        module Byebug
          byebug

          puts 'Hello world'
        end
      EOP
    end

    def test_ps_prints_expression_and_sorts_and_columnize_the_result
      with_setting :width, 20 do
        enter 'ps [1, 2, 3, 4, 5, 9, 8, 7, 6]'
        debug_code(program)

        check_output_includes '1  3  5  7  9', '2  4  6  8'
      end
    end
  end
end
