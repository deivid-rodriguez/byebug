# frozen_string_literal: true

require "test_helper"

module Byebug
  #
  # Tests commands which deal with backtraces.
  #
  class WhereStandardTest < TestCase
    def program
      strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    #
         3:    # Toy class to test backtraces.
         4:    #
         5:    class #{example_class}
         6:      def initialize(l)
         7:        @letter = encode(l)
         8:      end
         9:
        10:      def encode(str)
        11:        to_int(str + "x") + 5
        12:      end
        13:
        14:      def to_int(str)
        15:        byebug
        16:        str.ord
        17:      end
        18:    end
        19:
        20:    frame = #{example_class}.new("f")
        21:
        22:    frame
        23:  end
      RUBY
    end

    def test_where_displays_current_backtrace_with_fullpaths_by_default
      enter "where"
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  #{example_full_class}.to_int(str#String) at #{example_path}:16
            #1  #{example_full_class}.encode(str#String) at #{example_path}:11
            #2  #{example_full_class}.initialize(l#String) at #{example_path}:7
            ͱ-- #3  Class.new(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_long_callstyle_by_default
      enter "where"
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  #{example_full_class}.to_int(str#String) at #{example_path}:16
            #1  #{example_full_class}.encode(str#String) at #{example_path}:11
            #2  #{example_full_class}.initialize(l#String) at #{example_path}:7
            ͱ-- #3  Class.new\(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_short_callstyle
      enter "set callstyle short", "where", "set callstyle long"
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  to_int(str) at #{example_path}:16
            #1  encode(str) at #{example_path}:11
            #2  initialize(l) at #{example_path}:7
            ͱ-- #3  new(*args) at #{example_path}:20
            #4  <module:Byebug> at #{example_path}:20
            #5  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_instance_exec_block_frames
      enter "where"
      program = strip_line_numbers <<-RUBY
         1:  module Byebug
         2:    class #{example_full_class}
         3:      def foo
         4:        Object.new.instance_exec do
         5:          byebug
         6:        end
         7:      end
         8:    end
         9:
        10:    #{example_full_class}.new.foo
        11:  end
      RUBY
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  block in #{example_full_class}.block in foo at #{example_path}:6
            #1  BasicObject.instance_exec(*args) at #{example_path}:4
            #2  #{example_full_class}.foo at #{example_path}:4
            #3  <module:Byebug> at #{example_path}:10
            #4  <top (required)> at #{example_path}:1
      TXT

      check_output_includes(*expected_output)
    end
  end

  #
  # Tests dealing with backtraces when the path being debugged is not deeply
  # nested.
  #
  # @note We skip this tests in Windows since the paths in this CI environment
  #   are usually very deeply nested and on OS X where tmp path is always
  #   deeply nested.
  #
  unless /cygwin|mswin|mingw|darwin/.match?(RUBY_PLATFORM)
    class WhereWithNotDeeplyNestedPathsTest < WhereStandardTest
      def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
        enter "set nofullpath", "where", "set fullpath"
        debug_code(program)

        expected_output = prepare_for_regexp <<-TXT
          --> #0  #{example_full_class}.to_int(str#String) at #{example_path}:16
              #1  #{example_full_class}.encode(str#String) at #{example_path}:11
              #2  #{example_full_class}.initialize(l#String) at #{example_path}:7
              ͱ-- #3  Class.new(*args) at #{example_path}:20
              #4  <module:Byebug> at #{example_path}:20
              #5  <top (required)> at #{example_path}:1
        TXT

        check_output_includes(*expected_output)
      end
    end
  end

  #
  # Tests dealing with backtraces when the path being debugged is deeply nested.
  #
  class WhereWithDeeplyNestedPathsTest < WhereStandardTest
    def setup
      @example_parent_folder = Dir.mktmpdir(nil)
      @example_folder = File.realpath(Dir.mktmpdir(nil, @example_parent_folder))

      super
    end

    def teardown
      super

      FileUtils.remove_dir(@example_parent_folder, true)
    end

    def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
      enter "set nofullpath", "where", "set fullpath"
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  #{example_full_class}.to_int(str#String) at ...
            #1  #{example_full_class}.encode(str#String) at ...
            #2  #{example_full_class}.initialize(l#String) at ...
            ͱ-- #3  Class.new(*args) at ...
            #4  <module:Byebug> at ...
            #5  <top (required)> at ...
      TXT

      check_output_includes(*expected_output)
    end
  end
end
