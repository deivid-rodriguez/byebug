module Byebug
  #
  # Tests putl functionality.
  #
  class PutlTestCase < TestCase
    def program
      <<-EOP
        module Byebug
          byebug

          puts 'Hello world'
        end
      EOP
    end

    def test_putl_prints_expression_and_columnize_the_result
      with_setting :width, 20 do
        enter 'putl [1, 2, 3, 4, 5, 9, 8, 7, 6]'
        debug_code(program)

        check_output_includes '1  3  5  8  6', '2  4  9  7'
      end
    end
  end
end
