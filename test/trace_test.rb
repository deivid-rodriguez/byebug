class TestTrace < TestDsl::TestCase
  before do
    untrace_var(:$bla) if defined?($bla)
  end

  describe 'tracing' do

    describe 'enabling' do
      it 'must trace execution by setting trace to on' do
        enter 'trace on', 'cont 7', 'trace off'
        debug_file 'trace'
        check_output_includes 'line tracing is on.',
                              "Tracing: #{fullpath('trace')}:4 $bla = 4",
                              "Tracing: #{fullpath('trace')}:7 $bla = 7"
      end

      it 'must be able to use a shortcut' do
        enter 'tr on', 'cont 7', 'trace off'
        debug_file 'trace'
        check_output_includes 'line tracing is on.',
                              "Tracing: #{fullpath('trace')}:4 $bla = 4",
                              "Tracing: #{fullpath('trace')}:7 $bla = 7"
      end

      it 'must correctly print lines containing % sign' do
        enter 'cont 7', 'trace on', 'next', 'trace off'
        debug_file 'trace'
        check_output_includes \
          "Tracing: #{fullpath('trace')}:8 $bla = (0 == (7 % $bla))"
      end

      describe 'when basename set' do
        temporary_change_hash Byebug.settings, :basename, true

        it 'must correctly print file lines' do
          enter 'tr on', 'cont 7', 'trace off'
          debug_file 'trace'
          check_output_includes \
            "Tracing: #{File.basename(fullpath('trace'))}:7 $bla = 7"
        end
      end
    end

    it 'must show an error message if given subcommand is incorrect' do
      enter 'trace bla'
      debug_file 'trace'
      check_error_includes \
        'expecting "on", "off", "var" or "variable"; got: "bla"'
    end

    describe 'disabling' do
      it 'must stop tracing by setting trace to off' do
        enter 'trace on', 'next', 'trace off'
        debug_file 'trace'
        check_output_includes "Tracing: #{fullpath('trace')}:4 $bla = 4"
        check_output_doesnt_include "Tracing: #{fullpath('trace')}:5 $bla = 5"
      end

      it 'must show a message when turned off' do
        enter 'trace off'
        debug_file 'trace'
        check_output_includes 'line tracing is off.'
      end
    end
  end

  describe 'tracing global variables' do
    it 'must track global variable' do
      enter 'trace variable bla'
      debug_file 'trace'
      check_output_includes "traced global variable 'bla' has value '3'",
                            "traced global variable 'bla' has value '7'"
    end

    it 'must be able to use a shortcut' do
      enter 'trace var bla'
      debug_file 'trace'
      check_output_includes "traced global variable 'bla' has value '3'"
    end

    it 'must track global variable with stop' do
      enter 'trace variable bla stop', 'break 7', 'cont'
      debug_file('trace') { state.line.must_equal 4 }
    end

    it 'must track global variable with nostop' do
      enter 'trace variable bla nostop', 'break 7', 'cont'
      debug_file('trace') { state.line.must_equal 7 }
    end

    describe 'errors' do
      it 'must show an error message if there is no such global variable' do
        enter 'trace variable foo'
        debug_file 'trace'
        check_error_includes "'foo' is not a global variable."
      end

      it 'must show an error message if subcommand is invalid' do
        enter 'trace variable bla foo'
        debug_file 'trace'
        check_error_includes 'expecting "stop" or "nostop"; got "foo"'
      end
    end
  end
end
