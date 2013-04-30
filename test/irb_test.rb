require_relative 'test_helper'

describe 'Irb Command' do
  include TestDsl

  def after_setup
    interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
    IRB::Irb.stubs(:new).returns(irb)
    Signal.trap('SIGINT', 'IGNORE')
  end

  def after_teardown
    Signal.trap('SIGINT', 'DEFAULT')
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
      skip('Segfaulting... skip until fixed')
      irb.expects(:eval_input)
      enter 'set autoirb', 'break 4', 'cont'
      debug_file 'irb'
    end
  end

  it 'must translate SIGINT into "cont" command' do
    skip 'TODO: Can\'t reliably test the signal, from time to time '       \
         'Signal.trap, which is defined in IRBCommand, misses the SIGINT ' \
         'signal, which makes the test suite exit. Not sure how to fix '   \
         'that...'
    irb.stubs(:eval_input).calls { Process.kill('SIGINT', Process.pid) }
    enter 'break 4', 'irb'
    debug_file('irb') { state.line.must_equal 4 }
  end

  describe 'setting context to $byebug_state' do
    before do
      $byebug_state = nil
      Byebug::Command.settings[:byebugtesting] = false
    end

    it 'must set $byebug_state if irb is in the debug mode' do
      byebug_state = nil
      irb.stubs(:eval_input).calls { byebug_state = $byebug_state }
      enter 'irb -d'
      debug_file('irb')
      byebug_state.must_be_kind_of Byebug::CommandProcessor::State
    end

    it 'must not set $byebug_state if irb is not in the debug mode' do
      byebug_state = nil
      irb.stubs(:eval_input).calls { byebug_state = $byebug_state }
      enter 'irb'
      debug_file('irb')
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
