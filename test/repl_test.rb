require_relative 'test_helper'

describe 'Repl commands' do
  include TestDsl

  describe 'Irb Command' do
    before do
      interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
      IRB::Irb.stubs(:new).returns(irb)
    end

    let(:irb) { stub(context: ->{}) }

    it 'must support next command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :next)
      enter 'irb'
      debug_file('irb') { state.line.must_equal 3 }
    end

    it 'must support step command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :step)
      enter 'irb'
      debug_file('irb') { state.line.must_equal 3 }
    end

    it 'must support cont command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
      enter 'break 4', 'irb'
      debug_file('irb') { state.line.must_equal 4 }
    end

    describe 'autoirb' do
      it 'must call irb automatically after breakpoint' do
        irb.expects(:eval_input)
        enter 'set autoirb', 'break 4', 'cont', 'set noautoirb'
        debug_file 'irb'
      end
    end

    describe 'setting context to $byebug_state' do
      temporary_change_hash Byebug::Command.settings, :testing, false

      it 'must set $byebug_state if irb is in the debug mode' do
        byebug_state = nil
        irb.stubs(:eval_input).calls { byebug_state = $byebug_state }
        enter 'irb -d'
        debug_file 'irb'
        byebug_state.must_be_kind_of Byebug::CommandProcessor::State
      end

      it 'must not set $byebug_state if irb is not in the debug mode' do
        byebug_state = nil
        irb.stubs(:eval_input).calls { byebug_state = $byebug_state }
        enter 'irb'
        debug_file 'irb'
        byebug_state.must_be_nil
      end
    end

    describe 'Post Mortem' do
      it 'must work in post-mortem mode' do
        irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
        enter 'cont', 'break 12', 'irb'
        debug_file('post_mortem') { state.line.must_equal 12 }
      end
    end
  end

  @has_pry = false
  describe 'Pry command' do
    before do
      interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
      Byebug::PryCommand.any_instance.expects(:pry)
    end

    it 'must support step command' do
      skip 'TODO'
    end

    it 'must support cont command' do
      skip 'TODO'
    end

    describe 'autopry' do
      it 'must call pry automatically after breakpoint' do
        skip 'TODO'
      end
    end

    describe 'setting context to $byebug_state' do
      temporary_change_hash Byebug::Command.settings, :testing, false

      it 'must set $byebug_state if irb is in the debug mode' do
        enter 'pry -d'
        debug_file 'irb'
        $byebug_state.must_be_kind_of Byebug::CommandProcessor::State
      end

      it 'must not set $byebug_state if irb is not in the debug mode' do
        enter 'pry'
        debug_file 'pry'
        $byebug_state.must_be_nil
      end
    end

    describe 'Post Mortem' do
      it 'must work in post-mortem mode' do
        skip 'TODO'
      end
    end
  end if @has_pry
end
