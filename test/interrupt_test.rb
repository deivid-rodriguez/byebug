class InterruptExample
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

class TestInterrupting < TestDsl::TestCase
  describe 'Interrupt Command' do

    describe 'method call behaviour' do

      it 'must interrupt on the next line' do
        enter 'interrupt'
        enter 'continue'
        debug_file('interrupt') do
          state.line.must_equal 3
          state.file.must_equal __FILE__
        end
      end

      describe 'when forcestep is set' do
        temporary_change_hash Byebug.settings, :forcestep, true

        it 'must interrupt on the next line' do
          enter 'interrupt'
          enter 'continue'
          debug_file('interrupt') do
            state.line.must_equal 3
            state.file.must_equal __FILE__
          end
        end

        describe 'block behaviour' do
          before { enter 'break 4', 'cont' }

          it 'must step into blocks' do
            enter 'interrupt'
            enter 'continue'
            debug_file('interrupt') do
              state.line.must_equal 5
            end
          end
        end
      end
    end
  end
end
