require_relative 'test_helper'

describe "Stepping Commands" do
  include TestDsl

  describe "Next Command" do

    describe "Usual mode" do

      before do
        @old_hashes = {}
        set_tmp_hash(Byebug::Command.settings, :force_stepping, false)
        enter 'break 10', 'cont'
      end

      after do
        restore_tmp_hash(Byebug::Command.settings, :force_stepping)
      end

      it "must go to the next line if forced by a setting" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 'next'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must go to the next line if forced by a setting (by shortcut)" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 'n'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must leave on the same line if forced by a setting" do
        enter 'next'
        debug_file('stepping') { state.line.must_equal 10 }
      end

      it "must go the specified number of lines forward by default" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 'next 2'
        debug_file('stepping') { state.line.must_equal 21 }
      end

      it "must go to the next line if forced by 'plus' sign" do
        enter 'next+'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must leave on the same line if forced by 'minus' sign" do
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
        enter 'cont', "next"
        debug_file('post_mortem')
        check_output_includes 'Unknown command: "next".  Try "help".', interface.error_queue
      end
    end
  end

  describe "Step Command" do

    describe "Usual mode" do

      before do
        @old_hashes = {}
        set_tmp_hash(Byebug::Command.settings, :force_stepping, false)
        enter 'break 10', 'cont'
      end

      after do
        restore_tmp_hash(Byebug::Command.settings, :force_stepping)
      end


      it "must go to the step line if forced by a setting" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 'step'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must go to the next line by shortcut" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 's'
        debug_file('stepping') { state.line.must_equal 11 }
      end

      it "must leave on the same line if forced by a setting" do
        enter 'step'
        debug_file('stepping') { state.line.must_equal 10 }
      end

      it "must go the specified number of lines forward by default" do
        set_tmp_hash(Byebug::Command.settings, :force_stepping, true)
        enter 'step 2'
        debug_file('stepping') { state.line.must_equal 15 }
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
        enter 'cont', "step"
        debug_file('post_mortem')
        check_output_includes 'Unknown command: "step".  Try "help".', interface.error_queue
      end
    end
  end

end
