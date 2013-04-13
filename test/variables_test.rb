require_relative 'test_helper'

describe "Variables Command" do
  include TestDsl

  def after_setup
    Byebug::Command.settings[:width] = 40
  end

  describe "class variables" do
    it "must show variables" do
      enter 'break 19', 'cont', 'var class'
      debug_file 'variables'
      check_output_includes "@@class_c = 3"
    end

    it "must be able to use shortcut" do
      enter 'break 19', 'cont', 'v cl'
      debug_file 'variables'
      check_output_includes "@@class_c = 3"
    end
  end

  describe "constants" do
    it "must show constants" do
      enter 'break 25', 'cont', 'var const VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST => "foo"'
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v co VariablesExample'
      debug_file 'variables'
      check_output_includes 'SOMECONST => "foo"'
    end

    it "must show an error message if the given object is not a Class or Module" do
      enter 'break 25', 'cont', 'var const v'
      debug_file 'variables'
      check_output_includes "Should be Class/Module: v"
    end
  end

  describe "globals" do
    it "must show global variables" do
      enter 'break 25', 'cont', 'var global'
      debug_file 'variables'
      check_output_includes '$glob = 100'
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v g'
      debug_file 'variables'
      check_output_includes '$glob = 100'
    end
  end

  describe "instance variables" do
    it "must show instance variables of the given object" do
      enter 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes "@inst_a = 1", "@inst_b = 2"
    end

    it "must show instance variables of self" do
      enter 'break 11', 'cont', 'var instance'
      debug_file 'variables'
      check_output_includes "@inst_a = 1", "@inst_b = 2"
    end

    it "must show instance variables" do
      enter 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes "@inst_a = 1", "@inst_b = 2"
    end

    it "must be able to use shortcut" do
      enter 'break 25', 'cont', 'v ins v'
      debug_file 'variables'
      check_output_includes "@inst_a = 1", "@inst_b = 2"
    end

    it "must cut long variable values according to :width setting" do
      enter 'set width 20', 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes '@inst_c = "1111111111111111...'
    end

    it "must show fallback message if value doesn't have #to_s or #inspect methods" do
      enter 'set width 21', 'break 25', 'cont', 'var instance v'
      debug_file 'variables'
      check_output_includes '@inst_d = *Error in evaluation*'
    end
  end

  describe "local variables" do
    it "must show local variables" do
      enter 'break 17', 'cont', 'var local'
      debug_file 'variables'
      check_output_includes "a => 4", "b => nil", "i => 1"
    end
  end

  # TODO: Need to write tests for 'var ct' command, but I can't install the
  # 'ruby-internal' gem on my machine, it fails to build gem native extension.

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      skip("No post morten mode for now")
      enter 'cont', 'var local'
      debug_file 'post_mortem'
      check_output_includes "x => nil", "z => 4"
    end
  end

end
