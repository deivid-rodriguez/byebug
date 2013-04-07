require_relative 'test_helper'

describe "Show Command" do
  include TestDsl

  describe "annotate" do
    temporary_change_method_value(Byebug, :annotate, nil)

    it "must show annotate setting" do
      enter 'show annotate'
      debug_file 'show'
      check_output_includes "Annotation level is 0"
    end

    it "must show annotate setting" do
      enter 'show annotate'
      debug_file 'show'
      Byebug.annotate.must_equal 0
    end
  end

  describe "args" do
    temporary_change_hash_value(Byebug::Command.settings, :argv, %w{foo bar})

    it "must show args" do
      Byebug.send(:remove_const, "RDEBUG_SCRIPT") if Byebug.const_defined?("RDEBUG_SCRIPT")
      enter 'show args'
      debug_file 'show'
      check_output_includes 'Argument list to give program being debugged when it is started is "foo bar".'
    end

    it "must not show the first arg if RDEBUG_SCRIPT is defined" do
      temporary_set_const(Byebug, "RDEBUG_SCRIPT", "bla") do
        enter 'show args'
        debug_file 'show'
        check_output_includes 'Argument list to give program being debugged when it is started is "bar".'
      end
    end
  end


  it "must show autolist" do
    temporary_change_hash_value(Byebug::Command.settings, :autolist, 1) do
      enter 'show autolist'
      debug_file 'show'
      check_output_includes 'autolist is on.'
    end
  end

  it "must show autoeval" do
    temporary_change_hash_value(Byebug::Command.settings, :autoeval, true) do
      enter 'show autoeval'
      debug_file 'show'
      check_output_includes 'autoeval is on.'
    end
  end

  it "must show autoreload" do
    temporary_change_hash_value(Byebug::Command.settings, :reload_source_on_change, true) do
      enter 'show autoreload'
      debug_file 'show'
      check_output_includes 'autoreload is on.'
    end
  end

  it "must show autoirb" do
    Byebug::IRBCommand.any_instance.stubs(:execute)
    temporary_change_hash_value(Byebug::Command.settings, :autoirb, 1) do
      enter 'show autoirb'
      debug_file 'show'
      check_output_includes 'autoirb is on.'
    end
  end

  it "must show basename" do
    temporary_change_hash_value(Byebug::Command.settings, :basename, true) do
      enter 'show basename'
      debug_file 'show'
      check_output_includes 'basename is on.'
    end
  end

  it "must show callstyle" do
    temporary_change_hash_value(Byebug::Command.settings, :callstyle, :short) do
      enter 'show callstyle'
      debug_file 'show'
      check_output_includes 'Frame call-display style is short.'
    end
  end

  it "must show forcestep" do
    temporary_change_hash_value(Byebug::Command.settings, :force_stepping, true) do
      enter 'show forcestep'
      debug_file 'show'
      check_output_includes 'force-stepping is on.'
    end
  end

  it "must show fullpath" do
    temporary_change_hash_value(Byebug::Command.settings, :full_path, true) do
      enter 'show fullpath'
      debug_file 'show'
      check_output_includes "Displaying frame's full file names is on."
    end
  end

  it "must show linetrace" do
    enter 'trace on', 'show linetrace', 'trace off'
    debug_file 'show'
    check_output_includes "line tracing is on."
  end

  describe "linetrace+" do
    it "must show a message when linetrace+ is on" do
      temporary_change_hash_value(Byebug::Command.settings, :tracing_plus, true) do
        enter 'show linetrace+'
        debug_file 'show'
        check_output_includes "line tracing style is different consecutive lines."
      end
    end

    it "must show a message when linetrace+ is off" do
      temporary_change_hash_value(Byebug::Command.settings, :tracing_plus, false) do
        enter 'show linetrace+'
        debug_file 'show'
        check_output_includes "line tracing style is every line."
      end
    end
  end


  it "must show listsize" do
    temporary_change_hash_value(Byebug::Command.settings, :listsize, 10) do
      enter 'show listsize'
      debug_file 'show'
      check_output_includes 'Number of source lines to list by default is 10.'
    end
  end

  it "must show port" do
    temporary_set_const(Byebug, "PORT", 12345) do
      enter 'show port'
      debug_file 'show'
      check_output_includes 'server port is 12345.'
    end
  end

  it "must show trace" do
    temporary_change_hash_value(Byebug::Command.settings, :stack_trace_on_error, true) do
      enter 'show trace'
      debug_file 'show'
      check_output_includes "Displaying stack trace is on."
    end
  end

  it "must show version" do
    enter 'show version'
    debug_file 'show'
    check_output_includes "byebug #{Byebug::VERSION}"
  end

  it "must show forcestep" do
    temporary_change_hash_value(Byebug::Command.settings, :width, 35) do
      enter 'show width'
      debug_file 'show'
      check_output_includes 'width is 35.'
    end
  end

  it "must show a message about unknown command" do
    enter 'show bla'
    debug_file 'show'
    check_output_includes 'Unknown show command bla'
  end


  describe "history" do
    describe "without arguments" do
      before do
        interface.histfile = "hist_file.txt"
        interface.history_save = true
        interface.history_length = 25
        enter 'show history'
        debug_file 'show'
      end

      it "must show history file" do
        check_output_includes /filename: The filename in which to record the command history is "hist_file\.txt"/
      end

      it "must show history save setting" do
        check_output_includes /save: Saving of history save is on\./
      end

      it "must show history length" do
        check_output_includes /size: Byebug history size is 25/
      end
    end

    describe "with 'filename' argument" do
      it "must show history filename" do
        interface.histfile = "hist_file.txt"
        enter 'show history filename'
        debug_file 'show'
        check_output_includes 'The filename in which to record the command history is "hist_file.txt"'
      end

      it "must show history save setting" do
        interface.history_save = true
        enter 'show history save'
        debug_file 'show'
        check_output_includes 'Saving of history save is on.'
      end

      it "must show history length" do
        interface.history_length = 30
        enter 'show history size'
        debug_file 'show'
        check_output_includes 'Byebug history size is 30'
      end
    end
  end


  describe "commands" do
    before { interface.readline_support = true }

    it "must not show records from readline if there is no readline support" do
      interface.readline_support = false
      enter 'show commands'
      debug_file 'show'
      check_output_includes "No readline support"
    end

    it "must show records from readline history" do
      temporary_set_const(Readline, "HISTORY", %w{aaa bbb ccc ddd eee fff}) do
        enter 'show commands'
        debug_file 'show'
        check_output_includes /1  aaa/
        check_output_includes /6  fff/
      end
    end

    it "must show last 10 records from readline history" do
      temporary_set_const(Readline, "HISTORY", %w{aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn}) do
        enter 'show commands'
        debug_file 'show'
        check_output_doesnt_include /3  ccc/
        check_output_includes /4  eee/
        check_output_includes /13  nnn/
      end
    end

    describe "with specified positions" do
      it "must show records within boundaries" do
        temporary_set_const(Readline, "HISTORY", %w{aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn}) do
          # Really don't know why it substracts 4, and shows starting from position 6
          enter 'show commands 10'
          debug_file 'show'
          check_output_doesnt_include /5  fff/
          check_output_includes /6  ggg/
          check_output_includes /13  nnn/
        end
      end

      it "must adjust first line if it is < 0" do
        temporary_set_const(Readline, "HISTORY", %w{aaa bbb ccc ddd eee fff ggg hhh iii jjj kkk lll mmm nnn}) do
          enter 'show commands 3'
          debug_file 'show'
          check_output_includes /1  bbb/
          check_output_includes /8  iii/
          check_output_doesnt_include /9  jjj/
        end
      end
    end
  end

  describe "Post Mortem" do
    temporary_change_hash_value(Byebug::Command.settings, :autolist, 0)

    it "must work in post-mortem mode" do
      skip("No post morten mode for now")
      enter 'cont', "show autolist"
      debug_file 'post_mortem'
      check_output_includes "autolist is off."
    end
  end

end
