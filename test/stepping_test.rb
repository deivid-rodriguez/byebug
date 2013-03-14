require_relative 'test_helper'

describe "Stepping Commands" do
  include TestDsl

  describe "Next Command" do

    describe "Usual mode" do

      before { enter 'break 10', 'cont' }

      it "must go to the next line if forced by a setting" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 'next'
          debug_file('stepping') { state.line.must_equal 11 }
        end
      end

      it "must go to the next line if forced by a setting (by shortcut)" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 'n'
          debug_file('stepping') { state.line.must_equal 11 }
        end
      end

      it "must leave on the same line if forced by a setting" do
        temporary_change_hash_value(
                          Byebug::Command.settings, :force_stepping, false) do
          enter 'next'
          debug_file('stepping') { state.line.must_equal 10 }
        end
      end

      it "must go to the specified number of lines forward by default" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 'next 2'
          debug_file('stepping') { state.line.must_equal 21 }
        end
      end

      it "must go to the next line if forced to do that by 'plus' sign" do
        enter 'next+'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must leave on the same line if forced to do that by 'minus' sign" do
        enter 'next-'
        debug_file('stepping') { state.line.must_equal 10 }
      end

      it "must ignore the setting if 'minus' is specified" do
        enter 'next-'
        debug_file('stepping') { state.line.must_equal 10 }
      end
    end

    describe "Post Mortem" do
      temporary_change_hash_value(Byebug::Command.settings, :autoeval, false)
      it "must not work in post-mortem mode" do
        skip("No post morten mode for now")
        #enter 'cont', "next"
        #debug_file('post_mortem')
        #check_output_includes 'Unknown command: "next".  Try "help".', interface.error_queue
      end
    end
  end


  describe "Step Command" do
    describe "Usual mode" do
      before { enter 'break 10', 'cont' }

      it "must go to the step line if forced by a setting" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 'step'
          debug_file('stepping') { state.line.must_equal 11 }
        end
      end

      it "must go to the next line by shortcut" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 's'
          debug_file('stepping') { state.line.must_equal 11 }
        end
      end

      it "must leave on the same line if forced by a setting" do
        temporary_change_hash_value(
                          Byebug::Command.settings, :force_stepping, false) do
          enter 'step'
          debug_file('stepping') { state.line.must_equal 10 }
        end
      end

      it "must go to the specified number of lines forward by default" do
        temporary_change_hash_value(
                           Byebug::Command.settings, :force_stepping, true) do
          enter 'step 2'
          debug_file('stepping') { state.line.must_equal 15 }
        end
      end

      it "must go to the step line if forced to do that by 'plus' sign" do
        enter 'step+'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must leave on the same line if forced to do that by 'minus' sign" do
        enter 'step-'
        debug_file('stepping') { state.line.must_equal 10 }
      end
    end

    describe "Post Mortem" do
      temporary_change_hash_value(Byebug::Command.settings, :autoeval, false)
      it "must not work in post-mortem mode" do
        skip("No post morten mode for now")
        #enter 'cont', "step"
        #debug_file('post_mortem')
        #check_output_includes 'Unknown command: "step".  Try "help".', interface.error_queue
      end
    end
  end

end
