module Byebug
  class SourceTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 2
        a = 3
      end

      File.open('source_example.txt', 'w') do |f|
        f.puts 'break 2'
        f.puts 'break 3 if true'
      end

      super
    end

    def teardown
      File.delete('source_example.txt')
    end

    %w(source so).each do |cmd_alias|
      define_method(:"test_#{cmd_alias}_runs_byebug_commands_from_file") do
        enter "#{cmd_alias} source_example.txt"
        debug_proc(@example) do
          assert_equal 2, Byebug.breakpoints[0].pos
          assert_equal 3, Byebug.breakpoints[1].pos
          assert_equal 'true', Byebug.breakpoints[1].expr
        end
      end

      define_method(:"test_#{cmd_alias}_shows_an_error_if_file_not_found") do
        enter "#{cmd_alias} blabla"
        debug_proc(@example)
        check_error_includes(/File ".*blabla" not found/)
      end

      define_method(:"test_#{cmd_alias}_without_arguments_shows_help") do
        enter 'source'
        debug_proc(@example)
        check_output_includes(
          /Executes file <file> containing byebug commands./)
      end
    end
  end
end
