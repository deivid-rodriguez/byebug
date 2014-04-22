module InterruptTest
  class Example
    def self.a(num)
      num += 2
      b(num)
    end

    def self.b(num)
      v2 = 5 if 1 == num ; [1, 2, v2].map { |a| a.to_f }
      c(num)
    end

    def self.c(num)
      num += 4
      num
    end
  end

  class InterruptTestCase < TestDsl::TestCase
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

    describe 'Interrupt Command' do
      describe 'method call behaviour' do
        it 'must interrupt on the next line' do
          enter 'interrupt', 'continue'
          debug_proc(@example) do
            state.line.must_equal 4
            state.file.must_equal __FILE__
          end
        end

        describe 'when forcestep is set' do
          temporary_change_hash Byebug::Setting, :forcestep, true

          it 'must interrupt on the next line' do
            enter 'interrupt', 'continue'
            debug_proc(@example) do
              state.line.must_equal 4
              state.file.must_equal __FILE__
            end
          end

          describe 'block behaviour' do
            before { enter 'break 24', 'cont' }

            it 'must step into blocks' do
              enter 'interrupt', 'continue'
              debug_proc(@example) { state.line.must_equal 25 }
            end
          end
        end
      end
    end
  end
end
