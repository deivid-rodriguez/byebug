module BreakpointsTest
  class Example
    def self.a(num)
      4
    end

    def b
      3
    end
  end

  class DeepExample
    def a
      z = 2
      b(z)
    end

    def b(num)
      v2 = 5 if 1 == num ; [1,2,v2].map { |a| a.to_f }
      c
    end

    def c
      z = 4
      z += 5
      byebug
    end
  end

  class BreakpointsTestCase < TestDsl::TestCase
    before do
      @example = -> do
        y = 3
        # A comment
        byebug
        z = 5
        Example.new.b
        Example.a(y+z)
      end
    end

    def first
      Byebug.breakpoints.first
    end

    def last
      Byebug.breakpoints.last
    end

    describe 'setting breakpoint in the current file' do
      before { enter 'break 33' }

      def check_first(field, value)
        debug_proc(@example) { first.send(field).must_equal value }
      end

      it('must have correct pos')        { check_first(:pos, 33)          }
      it('must have correct source')     { check_first(:source, __FILE__) }
      it('must have correct expression') { check_first(:expr, nil)        }
      it('must have correct hit count')  { check_first(:hit_count, 0)     }
      it('must have correct hit value')  { check_first(:hit_value, 0)     }
      it('must be enabled')              { check_first(:enabled?, true)   }

      it('must return right response') do
        id = nil
        debug_proc(@example) { id = first.id }
        check_output_includes "Created breakpoint #{id} at #{__FILE__}:33"
      end
    end

    describe 'using shortcut for the command' do
      before { enter 'b 33' }
      it 'must set a breakpoint' do
        debug_proc(@example) { Byebug.breakpoints.size.must_equal 1 }
      end
    end

    describe 'setting breakpoint to unexistent line' do
      before { enter 'break 1000' }

      it 'must not create a breakpoint' do
        debug_proc(@example) { Byebug.breakpoints.must_be_empty }
      end

      it 'must show an error' do
        debug_proc(@example)
        check_error_includes \
          "There are only #{LineCache.size(__FILE__)} lines in file #{__FILE__}"
      end
    end

    describe 'setting breakpoint to incorrect line' do
      before { enter 'break 6' }

      it 'must not create a breakpoint' do
        debug_proc(@example) { Byebug.breakpoints.must_be_empty }
      end

      it 'must show an error' do
        debug_proc(@example)
        check_error_includes \
          "Line 6 is not a stopping point in file #{__FILE__}"
      end
    end

    describe 'stopping at breakpoint' do
      before { enter 'break 37', 'cont' }

      it 'must stop at the correct line' do
        debug_proc(@example) { state.line.must_equal 37 }
      end

      it 'must stop at the correct file' do
        debug_proc(@example) { state.file.must_equal __FILE__ }
      end

      describe 'show a message' do
        describe 'with full filename' do
          it 'must show a message with full filename' do
            debug_proc(@example) { @id = first.id }
            check_output_includes "Created breakpoint #{@id} at #{__FILE__}:37"
          end
        end

        describe 'with basename' do
          temporary_change_hash Byebug::Setting, :basename, true

          it 'must show a message with basename' do
            debug_proc(@example) { @id = first.id }
            check_output_includes \
              "Created breakpoint #{@id} at #{File.basename(__FILE__)}:37"
          end
        end
      end
    end

    describe 'reloading source on change' do
      describe 'autoreload not set' do
        temporary_change_hash Byebug::Setting, :autoreload, false

        it 'must not reload source' do
          id = nil
          enter \
            -> { change_line_in_file(__FILE__, 37, ''); 'break 37' },
            -> { change_line_in_file(__FILE__, 37, '        Example.new.b');
                cont }

          debug_proc(@example) { id = first.id }
          check_output_includes "Created breakpoint #{id} at #{__FILE__}:37"
        end
      end

      describe 'autoreload set' do
        it 'must reload source' do
          enter \
            -> { change_line_in_file(__FILE__, 37, ''); 'break 37' },
            -> { change_line_in_file(__FILE__, 37, '        Example.new.b');
              'next' }

          debug_proc(@example)
          check_error_includes \
            "Line 37 is not a stopping point in file #{__FILE__}"
        end
      end
    end

    describe 'set breakpoint in a file' do
      describe 'successfully' do
        before { enter "break #{__FILE__}:4", 'cont' }

        it 'must stop at the correct line' do
          debug_proc(@example) { state.line.must_equal 4 }
        end

        it 'must stop at the correct file' do
          debug_proc(@example) { state.file.must_equal __FILE__ }
        end
      end

      describe 'when setting breakpoint to unexisted file' do
        before do
          enter 'break asf:324'
          debug_proc(@example)
        end

        it 'must show an error' do
          check_error_includes 'No source file named asf'
        end

        it 'must ask about setting breakpoint anyway' do
          check_output_includes \
            'Set breakpoint anyway? (y/n)', interface.confirm_queue
        end
      end
    end

    describe 'set breakpoint to a method' do
      describe 'set breakpoint to an instance method' do
        before { enter 'break Example#b', 'cont' }

        it 'must stop at the correct line' do
          debug_proc(@example) { state.line.must_equal 7 }
        end

        it 'must stop at the correct file' do
          debug_proc(@example) { state.file.must_equal __FILE__ }
        end
      end

      describe 'set breakpoint to a class method' do
        before { enter 'break Example.a', 'cont' }

        it 'must stop at the correct line' do
          debug_proc(@example) { state.line.must_equal 3 }
        end

        it 'must stop at the correct file' do
          debug_proc(@example) { state.file.must_equal __FILE__ }
        end
      end

      describe 'set breakpoint to unexisted class' do
        it 'must show an error' do
          enter 'break B.a'
          debug_proc(@example)
          check_error_includes 'Unknown class B.'
        end
      end
    end

    describe 'set breakpoint to an invalid location' do
      before { enter 'break foo' }

      it 'must not create a breakpoint' do
        debug_proc(@example) { Byebug.breakpoints.must_be_empty }
      end

      it 'must show an error' do
        debug_proc(@example)
        check_error_includes 'Invalid breakpoint location: foo.'
      end
    end

    describe 'disabling breakpoints' do
      describe 'successfully' do
        before { enter 'break 37', 'break 38' }

        describe 'short syntax' do
          before { enter ->{ "disable #{first.id}" } }

          it 'must have a breakpoint with #enabled? returning false' do
            debug_proc(@example) { first.enabled?.must_equal false }
          end

          it 'must not stop on the disabled breakpoint' do
            enter 'cont'
            debug_proc(@example) { state.line.must_equal 38 }
          end
        end

        describe 'full syntax' do
          describe 'with no args' do
            before { enter 'disable breakpoints' }

            it 'must have all breakoints with #enabled? returning false' do
              debug_proc(@example) do
                first.enabled?.must_equal false
                last.enabled?.must_equal false
              end
            end

            it 'must not stop on any disabled breakpoint' do
              enter 'cont'
              debug_proc(@example)
              # Obscure assert to check for program termination
              state.proceed.must_equal true
            end
          end

          describe 'with specific breakpoint' do
            before do
              enter ->{ "disable breakpoints #{first.id}" }
            end

            it 'must have a breakpoint with #enabled? returning false' do
              debug_proc(@example) {
                first.enabled?.must_equal false }
            end
          end
        end
      end

      describe 'unsuccesfully' do
        it 'must show an error if syntax is incorrect' do
          enter 'disable'
          debug_proc(@example)
          check_error_includes '"disable" must be followed by "display", ' \
                               '"breakpoints" or breakpoint numbers.'
        end

        it 'must show an error if no breakpoints are set' do
          enter 'disable 1'
          debug_proc(@example)
          check_error_includes 'No breakpoints have been set.'
        end

        it 'must show an error if a number is not provided as an argument' do
          enter 'break 5', 'disable foo'
          debug_proc(@example)
          check_output_includes \
            '"disable breakpoints" argument "foo" needs to be a number'
        end
      end
    end

    describe 'enabling breakpoints' do
      describe 'successfully' do
        before { enter 'break 37', 'break 38', 'disable breakpoints' }

        describe 'short syntax' do
          before { enter ->{ "enable #{first.id}" } }

          it 'must have a breakpoint with #enabled? returning true' do
            debug_proc(@example) { first.enabled?.must_equal true }
          end

          it 'must stop on the enabled breakpoint' do
            enter 'cont'
            debug_proc(@example) { state.line.must_equal 37 }
          end
        end

        describe 'full syntax' do
          describe 'with no args' do
            before { enter 'enable breakpoints' }

            it 'must have all breakoints with #enabled? returning true' do
              debug_proc(@example) do
                first.enabled?.must_equal true
                last.enabled?.must_equal true
              end
            end

            it 'must stop on the first breakpoint' do
              enter 'cont'
              debug_proc(@example) { state.line.must_equal 37 }
            end

            it 'must stop on the last breakpoint' do
              enter 'cont', 'cont'
              debug_proc(@example) { state.line.must_equal 38 }
            end
          end

          describe 'with specific breakpoint' do
            before { enter ->{ "enable breakpoints #{last.id}" } }

            it 'must have a breakpoint with #enabled? returning true' do
              debug_proc(@example) { last.enabled?.must_equal true }
            end

            it 'must stop only on the enabled breakpoint' do
              enter 'cont'
              debug_proc(@example) { state.line.must_equal 38 }
            end
          end
        end
      end

      describe 'errors' do
        it 'must show an error if syntax is incorrect' do
          enter 'enable'
          debug_proc(@example)
          check_error_includes '"enable" must be followed by "display", ' \
                               '"breakpoints" or breakpoint numbers.'
        end
      end
    end

    describe 'deleting a breakpoint' do
      before { enter 'break 37', -> { "delete #{first.id}" }, 'break 38' }

      it 'must have only one breakpoint' do
        debug_proc(@example) { Byebug.breakpoints.size.must_equal 1 }
      end

      it 'must not stop on the disabled breakpoint' do
        enter 'cont'
        debug_proc(@example) { state.line.must_equal 38 }
      end
    end

    describe 'Conditional breakpoints' do
      it 'must stop if the condition is true' do
        enter 'break 37 if z == 5', 'break 38', 'cont'
        debug_proc(@example) { state.line.must_equal 37 }
      end

      it 'must skip if the condition is false' do
        enter 'break 37 if z == 3', 'break 38', 'cont'
        debug_proc(@example) { state.line.must_equal 38 }
      end

      it 'must show an error when conditional syntax is wrong' do
        enter 'break 37 ifa z == 3', 'break 38', 'cont'
        debug_proc(@example) { state.line.must_equal 38 }
        check_error_includes \
          'Expecting "if" in breakpoint condition; got: ifa z == 3.'
      end

      describe 'enabling with wrong conditional syntax' do
        before do
          enter 'break 37', -> { "disable #{first.id}" },
                            -> { "cond #{first.id} z -=( 3" },
                            -> { "enable #{first.id}"}
        end

        it 'must not enable a breakpoint' do
          debug_proc(@example) { first.enabled?.must_equal false }
        end

        it 'must show an error' do
          debug_proc(@example)
          check_error_includes 'Expression "z -=( 3" syntactically incorrect; ' \
                               'breakpoint remains disabled.'
        end
      end

      it 'must show an error if no file or line is specified' do
        enter 'break ifa z == 3', 'break 38', 'cont'
        debug_proc(@example) { state.line.must_equal 38 }
        check_error_includes 'Invalid breakpoint location: ifa z == 3.'
      end

      it 'must show an error if expression syntax is invalid' do
        enter 'break if z -=) 3', 'break 38', 'cont'
        debug_proc(@example) { state.line.must_equal 38 }
        check_error_includes \
          'Expression "z -=) 3" syntactically incorrect; breakpoint disabled.'
      end
    end

    describe 'Stopping through `byebug` keyword' do
      describe 'when not the last instruction of a method' do
        it 'must stop in the next line' do
          debug_proc(@example) { state.line.must_equal 36 }
        end
      end

      describe 'when last instruction of a method' do
        before do
          @deep_example = lambda do
            ex = DeepExample.new.a
            2.times do
              ex = ex ? ex : 1
            end
          end
        end

        it 'must stop right before returning from the frame' do
          debug_proc(@deep_example) { state.line.must_equal 27 }
        end
      end
    end

    describe 'Help' do
      it 'must show info about setting breakpoints when using just "break"' do
        enter 'break', 'cont'
        debug_proc(@example)
        check_output_includes(/b\[reak\] file:line \[if expr\]/)
      end
    end
  end
end
