require 'mocha/mini_test'

module Byebug
  module RemoteTest
    class StartServerTest < TestCase
      def teardown
        # Byebug#start_server defines an instance variable on the Byebug
        # metaclass during its first run.  This will pollute subsequent runs
        # unless removed.
        if Byebug.instance_variable_defined?(:@thread)
          Byebug.remove_instance_variable(:@thread)
        end
      end

      def test_start_server_starts_only_one_thread
        Mutex.expects(:new).once

        Byebug.start_server()
        Byebug.start_server()
      end

      def test_start_server_calls_a_block_passed_in
        Mutex.stubs(:new)
        yielded = false
        block = lambda { yielded = true }
        Byebug.start_server(&block)

        assert_equal(true, yielded)
      end
    end
  end
end
