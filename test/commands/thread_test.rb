# module Byebug
#   #
#   # Tests threading functionality.
#   #
#   class ThreadTestCase < TestCase
#     def program
#       strip_line_numbers <<-EOC
#          1:  module Byebug
#          2:    #
#          3:    # Toy class to test threading
#          4:    #
#          5:    class #{example_class}
#          6:      def initialize
#          7:        Thread.main[:should_break] = false
#          8:      end
#          9:
#         10:      def launch
#         11:        @t1 = Thread.new do
#         12:          loop do
#         13:            break if Thread.main[:should_break]
#         14:            sleep 0.02
#         15:          end
#         16:        end
#         17:
#         18:        @t2 = Thread.new do
#         19:          loop do
#         20:            sleep 0.02
#         21:          end
#         22:        end
#         23:
#         24:        @t1.join
#         25:        Thread.main[:should_break]
#         26:      end
#         27:
#         28:      def kill
#         29:        @t2.kill
#         30:      end
#         31:    end
#         32:
#         33:    byebug
#         34:
#         35:    t = #{example_class}.new
#         36:    t.launch
#         37:    t.kill
#         38:  end
#       EOC
#     end
#
#     def release
#       @release ||= 'eval Thread.main[:should_break] = true'
#     end
#
#     def first_thnum
#       Byebug.contexts.first.thnum
#     end
#
#     def last_thnum
#       Byebug.contexts.last.thnum
#     end
#
#     def test_thread_list_marks_current_thread_with_a_plus_sign
#       thnum, file = nil. example_path
#       enter 'break 11', 'cont', 'thread list', release
#       debug_code(program) { thnum = first_thnum }
#       check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{file}:11/)
#     end
#
#     def test_thread_list_works_with_shortcut
#       thnum, file = nil, example_path
#       enter 'break 11', 'cont', 'th list', release
#       debug_code(program) { thnum = first_thnum }
#       check_output_includes(/\+ #{thnum} #<Thread:\S+ run>\t#{file}:11/)
#     end
#
#     def test_thread_list_show_all_available_threads
#       enter 'break 24', 'cont', 'thread list', release
#       debug_code(program)
#       check_output_includes(/(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
#                             /(\+)?\d+ #<Thread:\S+ (sleep|run)>/,
#                             /(\+)?\d+ #<Thread:\S+ (sleep|run)>/)
#     end
#
#     def test_thread_stop_marks_thread_as_suspended
#       thnum = nil
#       enter 'break 24', 'cont', -> { "thread stop #{last_thnum}" }, release
#       debug_code(program) { thnum = last_thnum }
#       check_output_includes(/\$ #{thnum} #<Thread:/)
#     end
#
#     def test_thread_stop_actually_suspends_thread_execution
#       file = example_path
#       enter 'break 24', 'cont', 'trace on',
#             -> { "thread stop #{last_thnum}" }, release
#       debug_code(program)
#       check_output_doesnt_include(/Tracing: #{file}:19/,
#                                   /Tracing: #{file}:20/)
#     end
#
#     def test_thread_stop_shows_error_when_thread_number_not_specified
#       enter 'break 11', 'cont', 'thread stop', release
#       debug_code(program)
#       check_error_includes '"thread stop" needs a thread number'
#     end
#
#     def test_thread_stop_shows_error_when_trying_to_stop_current_thread
#       enter 'break 11', 'cont', -> { "thread stop #{first_thnum}" }, release
#       debug_code(program)
#       check_error_includes "It's the current thread"
#     end
#
#     def test_thread_resume_removes_threads_from_the_suspended_state
#       thnum = nil
#       enter 'break 24', 'cont',
#             -> { thnum = last_thnum; "thread stop #{thnum}" },
#             -> { "thread resume #{thnum}" }, release
#       debug_code(program) do
#         assert_equal false, Byebug.contexts.last.suspended?
#       end
#       check_output_includes(/\$ #{thnum} #<Thread:/, /#{thnum} #<Thread:/)
#     end
#
#     def test_thread_resume_shows_error_if_thread_number_not_specified
#       enter 'break 11', 'cont', 'thread resume', release
#       debug_code(program)
#       check_error_includes '"thread resume" needs a thread number'
#     end
#
#     def test_thread_resume_shows_error_when_trying_to_resume_current_thread
#       enter 'break 11', 'cont', -> { "thread resume #{first_thnum}" }, release
#       debug_code(program)
#       check_error_includes "It's the current thread"
#     end
#
#     def test_thread_resume_shows_error_if_thread_is_already_running
#       enter 'break 24', 'cont', -> { "thread resume #{last_thnum}" }, release
#       debug_code(program)
#       check_error_includes 'Already running'
#     end
#
#     def test_thread_switch_changes_execution_to_another_thread
#       enter 'break 24', 'cont', -> { "thread switch #{last_thnum}" }, release
#       debug_code(program) { assert_equal state.line, 19 }
#     end
#
#     def test_thread_switch_shows_error_if_thread_number_not_specified
#       enter 'break 11', 'cont', 'thread switch', release
#       debug_code(program)
#       check_error_includes '"thread switch" needs a thread number'
#     end
#
#     def test_thread_switch_shows_error_when_trying_to_switch_current_thread
#       enter 'break 11', 'cont', -> { "thread switch #{first_thnum}" }, release
#       debug_code(program)
#       check_error_includes "It's the current thread"
#     end
#   end
# end
