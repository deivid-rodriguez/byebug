module Byebug
  #
  # Tests eval functionality.
  #
  class PpTestCase < TestCase
    def program
      <<-EOP
        module Byebug
          byebug

          puts 'Hello world'
        end
      EOP
    end

    def test_pp_pretty_print_the_expressions_result
      enter "pp { a: '3' * 40, b: '4' * 30 }"
      debug_code(program)

      check_output_includes "{:a=>\"#{'3' * 40}\",", ":b=>\"#{'4' * 30}\"}"
    end
  end
end
