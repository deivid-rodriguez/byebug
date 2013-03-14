if RUBY_PLATFORM =~ /darwin/
require_relative 'test_helper'

describe "Tmate Command" do
  include TestDsl

  it "must open a current file with current frame in Textmate" do
    Byebug::TextMateCommand.any_instance.expects(:`).with("open 'txmt://open?url=file://#{fullpath('tmate')}&line=7'")
    enter 'break 7', 'cont', 'tmate'
    debug_file 'tmate'
  end

  it "must open a current file with specified frame in Textmate" do
    Byebug::TextMateCommand.any_instance.expects(:`).with("open 'txmt://open?url=file://#{fullpath('tmate')}&line=4'")
    enter 'break 7', 'cont', 'tmate 2'
    debug_file 'tmate'
  end

  describe "errors" do
    it "must show an error message if frame == 0" do
      enter 'tmate 0'
      debug_file 'tmate'
      check_output_includes "Wrong frame number"
    end

    it "must show an error message if frame > max frame" do
      enter 'tmate 10'
      debug_file 'tmate'
      check_output_includes "Wrong frame number"
    end
  end

  describe "Post Mortem" do
    it "must work in post-mortem mode" do
      skip("No post morten mode for now")
      #Byebug::TextMateCommand.any_instance.expects(:`).with(
      #  "open 'txmt://open?url=file://#{fullpath('post_mortem')}&line=8'"
      #)
      #enter 'cont', 'tmate'
      #debug_file 'post_mortem'
    end
  end
end
end
