module ReplTest
  class ReplTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 2
        a = 3
        a = 4
        a = 5
        a = 6
      end
    end

    describe 'Irb Command' do
      before do
        interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
        IRB::Irb.stubs(:new).returns(irb)
      end

      let(:irb) { stub(context: ->{}) }

      it 'must support next command' do
        irb.stubs(:eval_input).throws(:IRB_EXIT, :next)
        enter 'irb'
        debug_proc(@example) { state.line.must_equal 7 }
      end

      it 'must support step command' do
        irb.stubs(:eval_input).throws(:IRB_EXIT, :step)
        enter 'irb'
        debug_proc(@example) { state.line.must_equal 7 }
      end

      it 'must support cont command' do
        irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
        enter 'break 8', 'irb'
        debug_proc(@example) { state.line.must_equal 8 }
      end

      it 'autoirb must call irb automatically after breakpoint' do
        irb.expects(:eval_input)
        enter 'set autoirb', 'break 8', 'cont', 'set noautoirb'
        debug_proc(@example)
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

      describe 'post-mortem' do
        it 'must work in post-mortem mode' do
          skip 'TODO'
        end
      end
    end if @has_pry
  end
end
