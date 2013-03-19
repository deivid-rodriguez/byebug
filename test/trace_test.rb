require_relative 'test_helper'

describe "Trace Command (test setup)" do
  include TestDsl

  describe "Trace Command" do

    before do
      @old_consts = {}
      @old_hashes = {}
      set_tmp_const(Byebug, "PROG_SCRIPT", fullpath('trace'))
      set_tmp_hash(Byebug::Command.settings, :basename, false)
      untrace_var(:$bla) if defined?($bla)
      #temporary_change_method_value(Byebug::Command.settings, :tracing, false)
    end

    after do
      restore_tmp_const(Byebug, "PROG_SCRIPT")
      restore_tmp_hash(Byebug::Command.settings, :basename)
    end

    describe "tracing" do

      describe "enabling" do
        it "must trace execution by setting trace to on" do
          enter 'trace on', 'next'
          debug_file 'trace'
          check_output_includes "Tracing: #{fullpath('trace')}:4 $bla = 4",
                                "Tracing: #{fullpath('trace')}:5 $bla = 5"
          check_output_doesnt_include "Tracing: #{fullpath('trace')}:6 $bla = 6"
        end

        it "must show a message when turned on" do
          enter 'trace on'
          debug_file 'trace'
          check_output_includes "Tracing on on current thread."
        end

        it "must be able to use a shortcut" do
          enter 'tr on'
          debug_file 'trace'
          check_output_includes "Tracing on on current thread."
        end
      end

      it "must show an error message if given subcommand is incorrect" do
        enter 'trace bla'
        debug_file 'trace'
        check_output_includes "expecting 'on', 'off', 'var' or 'variable'; got: bla", interface.error_queue
      end

      describe "disabling" do
        it "must stop tracing by setting trace to off" do
          enter 'trace on', 'next', 'trace off'
          debug_file 'trace'
          check_output_includes "Tracing:#{fullpath('trace')}:3 $bla = 3"
          check_output_doesnt_include "Tracing:#{fullpath('trace')}:4 $bla = 4"
        end

        it "must show a message when turned off" do
          enter 'trace off'
          debug_file 'trace'
          check_output_includes "Tracing off on current thread."
        end
      end
    end

    #
    # XXX: No thread support
    #
    # describe "tracing on all thread" do
    #   describe "enabling" do
    #     it "must trace execution by setting trace to on" do
    #       temporary_set_const(Byebug, "PROG_SCRIPT", fullpath('trace_threads')) do
    #         thnum = nil
    #         enter 'trace on all'
    #         debug_file('trace_threads') { thnum = context.thnum }
    #         check_output_includes(
    #           "Tracing(#{thnum}):#{fullpath('trace_threads')}:4 @break1 = false",
    #           "Tracing(#{thnum}):#{fullpath('trace_threads')}:5 @break2 = false"
    #         )
    #         check_output_includes /Tracing\(\d+\):#{fullpath('trace_threads')}:8 until @break1/
    #       end
    #     end

    #     it "must show a message it is on" do
    #       enter 'trace on all'
    #       debug_file 'trace'
    #       check_output_includes "Tracing on all threads."
    #     end
    #   end

    #   describe "disabling" do
    #     it "must stop tracing by setting trace to off" do
    #       temporary_set_const(Byebug, "PROG_SCRIPT", fullpath('trace_threads')) do
    #         thnum = nil
    #         enter 'trace on all', 'break 19', 'cont', 'trace off all'
    #         debug_file('trace_threads') { thnum = context.thnum }
    #         check_output_includes /Tracing\(\d+\):#{fullpath('trace_threads')}:8 until @break1/
    #         check_output_includes "Tracing(#{thnum}):#{fullpath('trace_threads')}:19 t1.join"
    #         check_output_doesnt_include "Tracing(#{thnum}):#{fullpath('trace_threads')}:20 t1"
    #       end
    #     end

    #     it "must show a message it is off" do
    #       enter 'trace off'
    #       debug_file 'trace'
    #       check_output_includes "Tracing off on current thread."
    #     end
    #   end
    # end

    describe "tracing global variables" do
      it "must track global variable" do
        enter 'trace variable $bla'
        debug_file 'trace'
        check_output_includes(
          "traced variable $bla has value 3",
          "traced variable $bla has value 7",
        )
      end

      it "must be able to use a shortcut" do
        enter 'trace var $bla'
        debug_file 'trace'
        check_output_includes "traced variable $bla has value 3"
      end

      it "must track global variable with stop" do
        enter 'trace variable $bla stop', 'break 7', 'cont'
        debug_file('trace') { state.line.must_equal 4 }
      end

      it "must track global variable with nostop" do
        enter 'trace variable $bla nostop', 'break 7', 'cont'
        debug_file('trace') { state.line.must_equal 7 }
      end

      describe "errors" do
        it "must show an error message if there is no such global variable" do
          enter 'trace variable $foo'
          debug_file 'trace'
          check_output_includes "$foo is not a global variable.", interface.error_queue
        end

        it "must show an error message if subcommand is invalid" do
          enter 'trace variable $bla foo'
          debug_file 'trace'
          check_output_includes "expecting 'stop' or 'nostop'; got foo", interface.error_queue
        end
      end
    end

    describe "Post Mortem" do
      it "must work in post-mortem mode" do
        skip("No post morten mode for now")
        enter 'cont', 'trace on'
        debug_file 'post_mortem'
        check_output_includes "Tracing on on current thread."
      end
    end

  end

end
