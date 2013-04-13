require_relative 'test_helper'

describe "Method Command" do
  include TestDsl

  # TODO: Need to write tests for 'method signature' command, but I can't
  # install the 'ruby-internal' gem on my machine, it fails to build gem native
  # extension.

  def after_setup
    Byebug::Command.settings[:autolist] = 0
  end

  describe "show instance method of a class" do
    it "must show using full command name" do
      enter 'break 15', 'cont', 'm MethodEx'
      debug_file 'method'
      check_output_includes /bla/
      check_output_doesnt_include /foo/
    end

    it "must show using shortcut" do
      enter 'break 15', 'cont', 'method MethodEx'
      debug_file 'method'
      check_output_includes /bla/
    end

    it "must show an error if specified object is not a class or module" do
      enter 'break 15', 'cont', 'm a'
      debug_file 'method'
      check_output_includes "Should be Class/Module: a"
    end
  end


  describe "show methods of an object" do
    it "must show using full command name" do
      enter 'break 15', 'cont', 'method instance a'
      debug_file 'method'
      check_output_includes /bla/
      check_output_doesnt_include /foo/
    end

    it "must show using shortcut" do
      enter 'break 15', 'cont', 'm i a'
      debug_file 'method'
      check_output_includes /bla/
    end
  end


  describe "show instance variables of an object" do
    it "must show using full name command" do
      enter 'break 15', 'cont', 'method iv a'
      debug_file 'method'
      check_output_includes '@a = "b"', '@c = "d"'
    end

    it "must show using shortcut" do
      enter 'break 15', 'cont', 'm iv a'
      debug_file 'method'
      check_output_includes '@a = "b"', '@c = "d"'
    end
  end

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      skip("No post morten mode for now")
      enter 'cont', 'm i self'
      debug_file 'post_mortem'
      check_output_includes /to_s/
    end
  end

end
