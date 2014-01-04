class SteppingExample
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

class SteppingRaiseFromRubyMethodExample
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

class SteppingRaiseFromCMethodExample
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

class TestStepping < TestDsl::TestCase

  describe 'Next Command' do

    describe 'method call behaviour' do
      before { enter "break #{__FILE__}:8", 'cont' }

      it 'must leave on the same line by default' do
        enter 'next'
        debug_file('stepping') { state.line.must_equal 8 }
      end

      it 'must go to the next line if forced by "plus" sign' do
        enter 'next+'
        debug_file('stepping') { state.line.must_equal 9 }
      end

      it 'must leave on the same line if forced by "minus" sign' do
        enter 'next-'
        debug_file('stepping') { state.line.must_equal 8 }
      end

      describe 'when forcestep is set' do
        temporary_change_hash Byebug.settings, :forcestep, true

        it 'must go to the next line' do
          enter 'next'
          debug_file('stepping') { state.line.must_equal 9 }
        end

        it 'must go to the next line (by shortcut)' do
          enter 'n'
          debug_file('stepping') { state.line.must_equal 9 }
        end

        it 'must go the specified number of lines forward by default' do
          enter 'next 2'
          debug_file('stepping') { state.line.must_equal 4 }
        end

        it 'must inform when not staying in the same frame' do
          enter 'next 2'
          debug_file('stepping')
          check_output_includes \
            'Next went up a frame because previous frame finished'
        end


        it 'must ignore it if "minus" is specified' do
          enter 'next-'
          debug_file('stepping') { state.line.must_equal 8 }
        end
      end
    end

    describe 'block behaviour' do
      before { enter 'break 4', 'cont' }

      it 'must step over blocks' do
        enter 'next'
        debug_file('stepping') { state.line.must_equal 8 }
      end
    end

    describe 'raise/rescue behaviour' do
      describe 'from c method' do
        before { enter "break #{__FILE__}:36", 'cont' }

        it 'must step over rescue' do
          enter 'next'
          debug_file('stepping_raise_from_c_method') { state.line.must_equal 38 }
        end
      end

      describe 'from ruby method' do
        before { enter "break #{__FILE__}:20", 'cont' }

        it 'must step over rescue' do
          enter 'next'
          debug_file('stepping_raise_from_ruby_method') { state.line.must_equal 22 }
        end
      end
    end
  end

  describe 'Step Command' do

    describe 'method call behaviour' do
      before { enter "break #{__FILE__}:8", 'cont' }

      it 'must leave on the same line if forced by a setting' do
        enter 'step'
        debug_file('stepping') { state.line.must_equal 8 }
      end

      it 'must go to the step line if forced to do that by "plus" sign' do
        enter 'step+'
        debug_file('stepping') { state.line.must_equal 9 }
      end

      it 'must leave on the same line if forced to do that by "minus" sign' do
        enter 'step-'
        debug_file('stepping') { state.line.must_equal 8 }
      end

      describe 'when forcestep is set' do
        temporary_change_hash Byebug.settings, :forcestep, true

        it 'must go to the step line if forced by a setting' do
          enter 'step'
          debug_file('stepping') { state.line.must_equal 9 }
        end

        it 'must go to the next line if forced by a setting (by shortcut)' do
          enter 's'
          debug_file('stepping') { state.line.must_equal 9 }
        end

        it 'must go the specified number of lines forward by default' do
          enter 'step 2'
          debug_file('stepping') { state.line.must_equal 13 }
        end
      end
    end

    describe 'block behaviour' do
      before { enter 'break 4', 'cont' }

      it 'must step into blocks' do
        enter 'step'
        debug_file('stepping') { state.line.must_equal 5 }
      end
    end
  end
end
