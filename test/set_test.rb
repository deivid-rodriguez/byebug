module SetTest
  class SetTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 2
        a = 3
      end
    end

    [:autoeval, :autoirb, :autoreload, :autosave, :basename, :forcestep,
     :fullpath, :post_mortem, :stack_on_error, :testing, :linetrace,
     :tracing_plus].each do |setting|
      describe "setting boolean #{setting} to on" do
        temporary_change_hash Byebug::Setting, setting, false

        it "must set #{setting} to on using on" do
          enter "set #{setting} on"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end

        it "must set #{setting} to on using 1" do
          enter "set #{setting} 1"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end

        it "must set #{setting} to on by default" do
          enter "set #{setting}"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal true
        end
      end

      describe "setting boolean #{setting} to off" do
        temporary_change_hash Byebug::Setting, setting, true

        it "must set #{setting} to off using off" do
          enter "set #{setting} off"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end

        it "must set #{setting} to on using 0" do
          enter "set #{setting} 0"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end

        it "must set #{setting} to off using 'no' prefix" do
          enter "set no#{setting}"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal false
        end
      end
    end

    describe 'shortcuts' do
      describe 'setting' do
        temporary_change_hash Byebug::Setting, :autosave, false

        it 'must set setting if shortcut not ambiguous' do
          enter 'set autos'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal true
        end

        it 'must not set setting if shortcut is ambiguous' do
          enter 'set auto'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal false
        end
      end

      describe 'unsetting' do
        temporary_change_hash Byebug::Setting, :autosave, true

        it 'must unset setting if shortcut not ambiguous' do
          enter 'set noautos'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal false
        end

        it 'must not set setting to off if shortcut ambiguous' do
          enter 'set noauto'
          debug_proc(@example)
          Byebug::Setting[:autosave].must_equal true
        end
      end
    end

#   describe 'messages' do
#     temporary_change_hash Byebug::Setting, :autolist, 0

#     it 'must show a message after setting' do
#       enter 'set autolist on'
#       debug_proc(@example)
#       check_output_includes 'autolist is on.'
#     end
#   end

#   describe 'testing' do
#     describe 'state' do
#       describe 'when setting "testing" to on' do
#         temporary_change_hash Byebug::Setting, :testing, false

#         it 'must get set' do
#           enter 'set testing', 'break 7', 'cont'
#           debug_proc(@example) {
#             state.must_be_kind_of Byebug::CommandProcessor::State }
#         end
#       end

#       describe 'when setting "testing" to off' do
#         temporary_change_hash Byebug::Setting, :testing, true

#         it 'must get unset' do
#           enter 'set notesting', 'break 7', 'cont'
#           debug_proc(@example) { state.must_be_nil }
#         end
#       end
#     end
#   end

#   describe 'histsize' do
#     after { Byebug::History.max_size = Byebug::History::DEFAULT_MAX_SIZE }

#     it 'must set maximum history size' do
#       enter 'set histsize 250'
#       debug_proc(@example)
#       Byebug::History.max_size.must_equal 250
#     end

#     it 'must show a message' do
#       enter 'set histsize 250'
#       debug_proc(@example)
#       check_output_includes "Byebug history's maximum size is 250"
#     end

#     it 'must show an error message if no size provided' do
#       enter 'set histsize'
#       debug_proc(@example)
#       check_output_includes 'You need to specify an argument for "set histsize"'
#     end
#   end

#   describe 'histfile' do
#     let(:filename) { File.expand_path('./.custom-byebug-hist') }

#     after { Byebug::History.file = Byebug::History::DEFAULT_FILE }

#     it 'must set history filename' do
#       enter "set histfile #{filename}"
#       debug_proc(@example)
#       Byebug::History.file.must_equal filename
#     end

#     it 'must show a message' do
#       enter "set histfile #{filename}"
#       debug_proc(@example)
#       check_output_includes "The command history file is \"#{filename}\""
#     end

#     it 'must show an error message if no filename provided' do
#       enter 'set histfile'
#       debug_proc(@example)
#       check_output_includes 'You need to specify a filename'
#     end
#   end

    [:listsize, :width].each do |setting|
      describe "setting integer setting #{setting}" do
        temporary_change_hash Byebug::Setting, setting, 80

        it 'must get correctly set' do
          enter "set #{setting} 120"
          debug_proc(@example)
          Byebug::Setting[setting].must_equal 120
        end
      end
    end

#   describe 'Help' do
#     it 'must show help when typing just "set"' do
#       enter 'set', 'cont'
#       debug_proc(@example)
#       check_output_includes(/List of "set" subcommands:/)
#     end
#   end
  end
end
