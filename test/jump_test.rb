require_relative 'test_helper'

class TestJump < TestDsl::TestCase

  describe "successful" do
    it "must jump with absolute line number" do
      skip("No jumping for now")
      enter 'break 6', 'cont', "jump 8 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 8 }
    end

    it "must not initialize skipped variables during jump" do
      skip("No jumping for now")
      enter 'break 6', 'cont', "jump 8 #{fullpath('jump')}", 'next'
      enter 'var local'
      debug_file('jump')
      check_output_includes "a => 2", "b => nil", "c => nil", "d => 5"
    end

    it "must jump with relative line number (-)" do
      skip("No jumping for now")
      enter 'break 8', 'cont', "jump -2 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 6 }
    end

    it "must jump with relative line number (+)" do
      skip("No jumping for now")
      enter 'break 8', 'cont', "jump +2 #{fullpath('jump')}"
      debug_file('jump') { state.line.must_equal 10 }
    end
  end

  describe "errors" do
    it "must show an error if line number is invalid" do
      skip("No jumping for now")
      enter 'jump bla'
      debug_file('jump')
      check_output_includes "Bad line number: bla", interface.error_queue
    end

    it "must show an error if line number is not specified" do
      skip("No jumping for now")
      enter 'jump'
      debug_file('jump')
      check_output_includes '"jump" must be followed by a line number',
                            interface.error_queue
    end

    describe "when there is no active code in specified line" do
      it "must not jump to there" do
        skip("No jumping for now")
        enter "jump 13 #{fullpath('jump')}"
        debug_file('jump') { state.line.must_equal 3 }
      end

      it "must show an error" do
        skip("No jumping for now")
        enter "jump 13 #{fullpath('jump')}"
        debug_file('jump')
        check_output_includes \
          "Couldn't find active code at #{fullpath('jump')}:13",
          interface.error_queue
      end
    end
  end

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      skip 'No jumping for now plus this test fails with "Segmentation '     \
           'fault". Probably need to fix it somehow or forbid this command ' \
           'in post mortem mode. Seems like state.context.frame_file and '   \
           'state.context.frame_line cause that.'
      enter 'cont', 'jump 12'
      debug_file 'post_mortem'
    end
  end

end
