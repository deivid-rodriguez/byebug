module SteppingTest
  class Example
    def self.a(num)
      num += 2
      b(num)
    end

    def self.b(num)
      v2 = 5 if 1 == num ; [1, 2, v2].map { |t| t.to_f }
      c(num)
    end

    def self.c(num)
      num += 4
      num
    end
  end

  class SteppingTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug

        ex = Example.a(7)
        2.times do
          ex += 1
        end

        Example.b(ex)
      end
    end

    describe 'Next Command' do
      describe 'method call behaviour' do
        before { enter 'break 9', 'cont' }

        it 'must leave on the same line by default' do
          enter 'next'
          debug_proc(@example) { state.line.must_equal 9 }
        end

        it 'must go to the next line if forced by "plus" sign' do
          enter 'next+'
          debug_proc(@example) { state.line.must_equal 10 }
        end

        it 'must leave on the same line if forced by "minus" sign' do
          enter 'next-'
          debug_proc(@example) { state.line.must_equal 9 }
        end

        describe 'when forcestep is set' do
          temporary_change_hash Byebug::Setting, :forcestep, true

          it 'must go to the next line' do
            enter 'next'
            debug_proc(@example) { state.line.must_equal 10 }
          end

          it 'must go to the next line (by shortcut)' do
            enter 'n'
            debug_proc(@example) { state.line.must_equal 10 }
          end

          it 'must go the specified number of lines forward by default' do
            enter 'next 2'
            debug_proc(@example) { state.line.must_equal 25 }
          end

          it 'must inform when not staying in the same frame' do
            enter 'next 2'
            debug_proc(@example)
            check_output_includes \
              'Next went up a frame because previous frame finished'
          end


          it 'must ignore it if "minus" is specified' do
            enter 'next-'
            debug_proc(@example) { state.line.must_equal 9 }
          end
        end
      end

      describe 'block behaviour' do
        before { enter 'break 57', 'cont' }

        it 'must step over blocks' do
          enter 'next'
          debug_proc(@example) { state.line.must_equal 24 }
        end
      end

      describe 'raise/rescue behaviour' do
        describe 'from c method' do
          before do
            @example_raise = -> do
              byebug

              class RaiseFromCMethodExample
                def a
                  b
                rescue NameError
                  1
                end

                def b
                  c
                end

                def c
                  d
                end
              end

              RaiseFromCMethodExample.new.a
            end
            enter 'break 102', 'cont'
          end

          it 'must step over rescue' do
            enter 'next'
            debug_proc(@example_raise) { state.line.must_equal 104 }
          end
        end

        describe 'from ruby method' do
          before do
            @example_raise = -> do
              byebug

              class RaiseFromRubyMethodExample
                def a
                  b
                rescue
                  1
                end

                def b
                  c
                end

                def c
                  raise 'bang'
                end
              end

              RaiseFromRubyMethodExample.new.a
            end
            enter 'break 134', 'cont'
          end

          it 'must step over rescue' do
            enter 'next'
            debug_proc(@example_raise) { state.line.must_equal 136 }
          end
        end
      end
    end

    describe 'Step Command' do

      describe 'method call behaviour' do
        before { enter 'break 9', 'cont' }

        it 'must leave on the same line if forced by a setting' do
          enter 'step'
          debug_proc(@example) { state.line.must_equal 9 }
        end

        it 'must go to the step line if forced to do that by "plus" sign' do
          enter 'step+'
          debug_proc(@example) { state.line.must_equal 10 }
        end

        it 'must leave on the same line if forced to do that by "minus" sign' do
          enter 'step-'
          debug_proc(@example) { state.line.must_equal 9 }
        end

        describe 'when forcestep is set' do
          temporary_change_hash Byebug::Setting, :forcestep, true

          it 'must go to the step line if forced by a setting' do
            enter 'step'
            debug_proc(@example) { state.line.must_equal 10 }
          end

          it 'must go to the next line if forced by a setting (by shortcut)' do
            enter 's'
            debug_proc(@example) { state.line.must_equal 10 }
          end

          it 'must go the specified number of lines forward by default' do
            enter 'step 2'
            debug_proc(@example) { state.line.must_equal 14 }
          end
        end
      end

      describe 'block behaviour' do
        before { enter 'break 25', 'cont' }

        it 'must step into blocks' do
          enter 'step'
          debug_proc(@example) { state.line.must_equal 26 }
        end
      end
    end
  end
end
