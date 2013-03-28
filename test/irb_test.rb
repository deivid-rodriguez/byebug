require_relative 'test_helper'

describe "Irb Command" do
  include TestDsl

  describe "Irb Command Setup" do
    before do
      interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
      IRB::Irb.stubs(:new).returns(irb)
      Signal.trap("SIGINT", "IGNORE")
    end
    after do
      Signal.trap("SIGINT", "DEFAULT")
    end
    let(:irb) { stub(context: ->{}) }

    it "must support next command" do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :next)
      enter 'irb'
      debug_file('irb') { state.line.must_equal 3 }
    end

    it "must support step command" do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :step)
      enter 'irb'
      debug_file('irb') { state.line.must_equal 3 }
    end

    it "must support cont command" do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
      enter 'break 4', 'irb'
      debug_file('irb') { state.line.must_equal 4 }
    end

    describe "autoirb" do
      temporary_change_hash_value(Byebug::Command.settings, :autoirb, 0)

      it "must call irb automatically after breakpoint" do
        irb.expects(:eval_input)
        enter 'set autoirb', 'break 4', 'cont'
        debug_file 'irb'
      end
    end

    # TODO: Can't reliably test the signal, from time to time Signal.trap, which
    # is defined in IRBCommand, misses the SIGINT signal, which makes the test
    # suite exit. Not sure how to fix that...
    it "must translate SIGINT into 'cont' command" do
      irb.stubs(:eval_input).calls { Process.kill("SIGINT", Process.pid) }
      enter 'break 4', 'irb'
      debug_file('irb') { state.line.must_equal 4 }
    end

    describe "setting context to $rdebug_state" do
      before { $rdebug_state = nil }
      temporary_change_hash_value(Byebug::Command.settings, :byebugtesting, false)

      it "must set $rdebug_state if irb is in the debug mode" do
        rdebug_state = nil
        irb.stubs(:eval_input).calls { rdebug_state = $rdebug_state }
        enter 'irb -d'
        debug_file('irb')
        rdebug_state.must_be_kind_of Byebug::CommandProcessor::State
      end

      it "must not set $rdebug_state if irb is not in the debug mode" do
        rdebug_state = nil
        irb.stubs(:eval_input).calls { rdebug_state = $rdebug_state }
        enter 'irb'
        debug_file('irb')
        rdebug_state.must_be_nil
      end
    end

    describe "Post Mortem" do
      it "must work in post-mortem mode" do
        skip("No post morten mode for now")
        irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
        enter 'cont', 'break 12', 'irb'
        debug_file("post_mortem") { state.line.must_equal 12 }
      end
    end

  end

end
