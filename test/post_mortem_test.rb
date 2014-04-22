module PostMortemTest
  class Example
    def a
      z = 4
      raise 'blabla'
      x = 6
      x + z
    end
  end

  class PostMortemTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        c = Example.new
        c.a
      end
    end

    describe 'Features' do
      before { enter 'set post_mortem', 'cont' }
      after { Byebug.post_mortem = false }

      it 'is rising right before exiting' do
        assert_raises(RuntimeError) do
          debug_proc(@example)
        end
      end

      it 'sets post_mortem to true' do
        begin
          debug_proc(@example)
        rescue
          Byebug.post_mortem?.must_equal true
        end
      end

      it 'stops at the correct line' do
        begin
          debug_proc(@example)
        rescue
          Byebug.raised_exception.__bb_line.must_equal 5
        end
      end
    end

    describe 'Unavailable commands' do
      temporary_change_hash Byebug::Setting, :autoeval, false

      %w(step next finish break condition display reload).each do |cmd|
        define_method "test_#{cmd}_is_forbidden_in_post_mortem_mode" do
          enter "#{cmd}"
          state.context.stubs(:dead?).returns(:true)
          begin
            debug_proc(@example)
          rescue RuntimeError
            check_error_includes 'Command unavailable in post mortem mode.'
          end
        end
      end
    end

    describe 'Available commands' do
      ['restart', 'frame', 'quit', 'edit', 'info', 'irb', 'source', 'help',
       'var class', 'list', 'method', 'kill', 'eval', 'set', 'save', 'show',
       'trace', 'thread list'].each do |cmd|
        define_method "test_#{cmd}_is_permitted_in_post_mortem_mode" do
          enter "#{cmd}"
          class_name = cmd.gsub(/(^| )\w/) { |b| b[-1,1].upcase } + 'Command'

          Byebug.const_get(class_name).any_instance.stubs(:execute)
          assert_raises(RuntimeError) { debug_proc(@example) }
        end
      end
    end
  end
end
