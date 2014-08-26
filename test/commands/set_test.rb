module Byebug
  class SetTestCase < TestCase
    def setup
      @example = -> do
        byebug
        a = 2
        a += 1
      end

      super
    end

    [:autoeval, :autolist, :autoreload, :autosave, :basename, :forcestep,
     :fullpath, :post_mortem, :stack_on_error, :testing,
     :tracing_plus].each do |set|
      ['on', '1', 'true', ''].each do |key|
        define_method(:"test_enable_boolean_setting_#{set}_using_#{key}") do
          Setting[set] = false
          enter "set #{set} #{key}"
          debug_proc(@example)
          assert_equal true, Setting[set]
        end
      end

      ['off', '0', 'false'].each do |key|
        define_method(:"test_disable_boolean_setting_#{set}_using_#{key}") do
          Setting[set] = true
          enter "set #{set} #{key}"
          debug_proc(@example)
          assert_equal false, Setting[set]
        end
      end

      define_method(:"test_disable_boolean_setting_#{set}_using_no_prefix") do
        Setting[set] = true
        enter "set no#{set}"
        debug_proc(@example)
        assert_equal false, Setting[set]
      end
    end

    def test_set_enables_a_setting_using_shorcut_when_not_ambiguous
      Setting[:forcestep] = false
      enter 'set fo'
      debug_proc(@example)
      assert_equal true, Setting[:forcestep]
    end

    def test_set_does_not_enable_a_setting_using_shorcut_when_ambiguous
      Setting[:forcestep] = false
      Setting[:fullpath] = false
      enter 'set f'
      debug_proc(@example)
      assert_equal false, Setting[:forcestep]
      assert_equal false, Setting[:fullpath]
    end

    def test_set_disables_a_setting_using_shorcut_when_not_ambiguous
      Setting[:forcestep] = true
      enter 'set nofo'
      debug_proc(@example)
      assert_equal false, Setting[:forcestep]
    end

    def test_set_does_not_disable_a_setting_using_shorcut_when_ambiguous
      Setting[:forcestep] = true
      Setting[:fullpath] = true
      enter 'set nof'
      debug_proc(@example)
      assert_equal true, Setting[:forcestep]
      assert_equal true, Setting[:fullpath]
    end

    def test_set_testing_sets_the_thread_state_variable
      Setting[:testing] = false
      enter 'set testing', 'break 7', 'cont'
      debug_proc(@example) do
        assert_kind_of CommandProcessor::State, state
      end
    end

    def test_set_notesting_unsets_the_thread_state_variable
      Setting[:testing] = true
      enter 'set notesting', 'break 7', 'cont'
      debug_proc(@example) { assert_nil state }
    end

    def test_set_histsize_sets_maximum_history_size
      Setting[:histsize] = 1
      enter 'set histsize 250'
      debug_proc(@example)
      assert_equal 250, Setting[:histsize]
      check_output_includes "Maximum size of byebug's command history is 250"
    end

    def test_set_histsize_shows_an_error_message_if_no_size_is_provided
      enter 'set histsize'
      debug_proc(@example)
      check_error_includes 'You must specify a value for setting :histsize'
    end

    def test_set_histfile_sets_command_history_file
      filename = File.expand_path('.custom-byebug-hist')
      enter "set histfile #{filename}"
      debug_proc(@example)
      assert_equal filename, Setting[:histfile]
      check_output_includes "The command history file is #{filename}"
    end

    def test_set_histfile_shows_an_error_message_if_no_filename_is_provided
      enter 'set histfile'
      debug_proc(@example)
      check_error_includes 'You must specify a value for setting :histfile'
    end

    [:listsize, :width].each do |set|
      define_method(:"test_set_#{set}_changes_integer_setting_#{set}") do
        Setting[set] = 80
        enter "set #{set} 120"
        debug_proc(@example)
        assert_equal 120, Setting[set]
      end
    end

    def test_verbose_prints_tracepoint_api_event_information
      enter 'set verbose'
      debug_proc(@example)
      assert_equal true, Byebug.verbose?
      Byebug.verbose = false
    end

    def test_set_without_arguments_shows_help_for_set_command
      enter 'set'
      debug_proc(@example)
      check_output_includes(/Modifies parts of byebug environment./)
      check_output_includes(/List of settings supported in byebug/)
    end
  end
end
