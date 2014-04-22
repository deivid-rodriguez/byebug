module TraceTest
  class TraceTestCase < TestDsl::TestCase
    before do
      @example = -> do
        $bla = 5
        byebug
        $bla = 7
        $bla = 8
        $bla = 9
        $bla = 10
        $bla = (0 == (10 % $bla))
      end
      untrace_var(:$bla) if defined?($bla)
    end

    describe 'line tracing' do
      describe 'enabling' do
        it 'must trace execution by setting trace to on' do
          enter 'set linetrace', 'cont 10', 'set nolinetrace'
          debug_proc(@example)
          check_output_includes 'linetrace is on',
                                "Tracing: #{__FILE__}:8 $bla = 8",
                                "Tracing: #{__FILE__}:10 $bla = 10"
        end

        it 'must be able to use a shortcut' do
          enter 'set lin on', 'cont 10', 'set nolin'
          debug_proc(@example)
          check_output_includes 'linetrace is on',
                                "Tracing: #{__FILE__}:8 $bla = 8",
                                "Tracing: #{__FILE__}:10 $bla = 10"
        end

        it 'must correctly print lines containing % sign' do
          enter 'cont 10', 'set linetrace', 'next', 'set nolinetrace'
          debug_proc(@example)
          check_output_includes "Tracing: #{__FILE__}:11 $bla = (0 == (10 % $bla))"
        end

        describe 'when basename set' do
          temporary_change_hash Byebug::Setting, :basename, true

          it 'must correctly print file lines' do
            enter 'set linetrace on', 'cont 10', 'set nolinetrace'
            debug_proc(@example)
            check_output_includes \
              "Tracing: #{File.basename(__FILE__)}:10 $bla = 10"
          end
        end
      end

      describe 'disabling' do
        it 'must stop tracing by setting trace to off' do
          enter 'set linetrace', 'next', 'set nolinetrace'
          debug_proc(@example)
          check_output_includes "Tracing: #{__FILE__}:8 $bla = 8"
          check_output_doesnt_include "Tracing: #{__FILE__}:9 $bla = 9"
        end

        it 'must show a message when turned off' do
          enter 'set nolinetrace'
          debug_proc(@example)
          check_output_includes 'linetrace is off'
        end
      end
    end

    describe 'global variable tracing' do
      it 'must track global variable' do
        enter 'tracevar bla'
        debug_proc(@example)
        check_output_includes "traced global variable 'bla' has value '7'",
                              "traced global variable 'bla' has value '10'"
      end

      it 'must be able to use a shortcut' do
        enter 'tracevar bla'
        debug_proc(@example)
        check_output_includes "traced global variable 'bla' has value '7'"
                              "traced global variable 'bla' has value '10'"
      end

      it 'must track global variable with stop' do
        enter 'tracevar bla stop', 'break 10', 'cont'
        debug_proc(@example) { state.line.must_equal 8 }
      end

      it 'must track global variable with nostop' do
        enter 'tracevar bla nostop', 'break 10', 'cont'
        debug_proc(@example) { state.line.must_equal 10 }
      end

      describe 'errors' do
        it 'must show an error message if there is no such global variable' do
          enter 'tracevar foo'
          debug_proc(@example)
          check_error_includes "'foo' is not a global variable."
        end

        it 'must show an error message if subcommand is invalid' do
          enter 'tracevar bla foo'
          debug_proc(@example)
          check_error_includes 'expecting "stop" or "nostop"; got "foo"'
        end
      end
    end
  end
end
