require_relative 'test_helper'

describe "Reload Command" do
  include TestDsl

  describe "Reload Command (Setup)" do

    before { Byebug::Command.settings[:reload_source_on_change] = false }

    it "must notify that automatic reloading is off" do
      enter 'reload'
      debug_file 'reload'
      check_output_includes "Source code is reloaded. Automatic reloading is off."
    end

    it "must notify that automatic reloading is on" do
      enter 'set autoreload', 'reload'
      debug_file 'reload'
      check_output_includes "Source code is reloaded. Automatic reloading is on."
    end

    describe "reloading" do
      after { change_line_in_file(fullpath('reload'), 4, '4') }
      it "must reload the code" do
        enter 'break 3', 'cont', 'l 4-4', -> do
          change_line_in_file(fullpath('reload'), 4, '100')
          'reload'
        end, 'l 4-4'
        debug_file 'reload'
        check_output_includes "4  100"
      end
    end

    describe "Post Mortem" do
       after { change_line_in_file(fullpath('post_mortem'), 7, '        z = 4') }
      it "must work in post-mortem mode" do
        skip("No post morten mode for now")
        enter 'cont', -> do
          change_line_in_file(fullpath('post_mortem'), 7, 'z = 100')
          'reload'
        end, 'l 7-7'
        debug_file 'post_mortem'
        check_output_includes "7  z = 100"
      end
    end

  end

end
