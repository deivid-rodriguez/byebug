class TestRepl < TestDsl::TestCase

  describe 'Irb Command' do
    before do
      interface.stubs(:kind_of?).with(Byebug::LocalInterface).returns(true)
      IRB::Irb.stubs(:new).returns(irb)
    end

    let(:irb) { stub(context: ->{}) }

    it 'must support next command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :next)
      enter 'irb'
      debug_file('repl') { state.line.must_equal 3 }
    end

    it 'must support step command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :step)
      enter 'irb'
      debug_file('repl') { state.line.must_equal 3 }
    end

    it 'must support cont command' do
      irb.stubs(:eval_input).throws(:IRB_EXIT, :cont)
      enter 'break 4', 'irb'
      debug_file('repl') { state.line.must_equal 4 }
    end

    describe 'autoirb' do
      it 'must call irb automatically after breakpoint' do
        irb.expects(:eval_input)
        enter 'set autoirb', 'break 4', 'cont', 'set noautoirb'
        debug_file 'repl'
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

    describe 'post-mortem' do
      it 'must work in post-mortem mode' do
        skip 'TODO'
      end
    end
  end if @has_pry
end
