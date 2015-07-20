# encoding: utf-8

require 'test_helper'
require 'mocha/mini_test'

module Byebug
  #
  # Tests commands which deal with backtraces.
  #
  class WhereTestCase < TestCase
    def program
      strip_line_numbers <<-EOP
         1:  module Byebug
         2:    #
         3:    # Toy class to test backtraces.
         4:    #
         5:    class #{example_class}
         6:      def initialize(letter)
         7:        @letter = encode(letter)
         8:      end
         9:
        10:      def encode(str)
        11:        integerize(str + 'x') + 5
        12:      end
        13:
        14:      def integerize(str)
        15:        byebug
        16:        str.ord
        17:      end
        18:    end
        19:
        20:    frame = #{example_class}.new('f')
        21:
        22:    frame
        23:  end
      EOP
    end

    def test_where_displays_current_backtrace_with_fullpaths_by_default
      enter 'where'
      debug_code(program)

      path = Pathname.new(example_path).realpath
      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::#{example_class}.integerize(str#String) at #{path}:16
            #1  Byebug::#{example_class}.encode(str#String) at #{path}:11
            #2  Byebug::#{example_class}.initialize(letter#String) at #{path}:7
            ͱ-- #3  Class.new(*args) at #{path}:20
            #4  <module:Byebug> at #{path}:20
            #5  <top (required)> at #{path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_current_backtrace_w_shorpaths_if_fullpath_disabled
      path = '.../shortpath/to/example.rb'
      Frame.any_instance.stubs(:shortpath).returns(path)

      enter 'set nofullpath', 'where', 'set fullpath'
      debug_code(program)

      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::#{example_class}.integerize(str#String) at #{path}:16
            #1  Byebug::#{example_class}.encode(str#String) at #{path}:11
            #2  Byebug::#{example_class}.initialize(letter#String) at #{path}:7
            ͱ-- #3  Class.new(*args) at #{path}:20
            #4  <module:Byebug> at #{path}:20
            #5  <top (required)> at #{path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_long_callstyle_by_default
      enter 'where'
      debug_code(program)

      path = Pathname.new(example_path).realpath
      expected_output = prepare_for_regexp <<-TXT
        --> #0  Byebug::#{example_class}.integerize(str#String) at #{path}:16
            #1  Byebug::#{example_class}.encode(str#String) at #{path}:11
            #2  Byebug::#{example_class}.initialize(letter#String) at #{path}:7
            ͱ-- #3  Class.new\(*args) at #{path}:20
            #4  <module:Byebug> at #{path}:20
            #5  <top (required)> at #{path}:1
      TXT

      check_output_includes(*expected_output)
    end

    def test_where_displays_backtraces_using_short_callstyle
      enter 'set callstyle short', 'where', 'set callstyle long'
      debug_code(program)

      path = Pathname.new(example_path).realpath
      expected_output = prepare_for_regexp <<-TXT
        --> #0  integerize(str) at #{path}:16
            #1  encode(str) at #{path}:11
            #2  initialize(letter) at #{path}:7
            ͱ-- #3  new(*args) at #{path}:20
            #4  <module:Byebug> at #{path}:20
            #5  <top (required)> at #{path}:1
      TXT

      check_output_includes(*expected_output)
    end
  end
end
