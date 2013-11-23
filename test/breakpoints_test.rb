class BreakpointExample
  def self.a(num)
    4
  end
  def b
    3
  end
end

class BreakpointDeepExample
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

class TestBreakpoints < TestDsl::TestCase
  before do
    @tst_file = fullpath('breakpoint')
  end

  describe 'setting breakpoint in the current file' do
    before { enter 'break 1' }

    subject { Byebug.breakpoints.first }

    def check_subject(field, value)
      debug_file('breakpoint') { subject.send(field).must_equal value }
    end

    it('must have correct pos')        { check_subject(:pos, 1)            }
    it('must have correct source')     { check_subject(:source, @tst_file) }
    it('must have correct expression') { check_subject(:expr, nil)         }
    it('must have correct hit count')  { check_subject(:hit_count, 0)      }
    it('must have correct hit value')  { check_subject(:hit_value, 0)      }
    it('must be enabled')              { check_subject(:enabled?, true)    }

    it('must return right response') do
      id = nil
      debug_file('breakpoint') { id = subject.id }
      check_output_includes "Created breakpoint #{id} at #{@tst_file}:1"
    end
  end

  describe 'using shortcut for the command' do
    before { enter 'b 1' }
    it 'must set a breakpoint' do
      debug_file('breakpoint') { Byebug.breakpoints.size.must_equal 1 }
    end
  end

  describe 'setting breakpoint to unexistent line' do
    before { enter 'break 100' }

    it 'must not create a breakpoint' do
      debug_file('breakpoint') { Byebug.breakpoints.must_be_empty }
    end

    it 'must show an error' do
      debug_file('breakpoint')
      check_error_includes \
        "There are only #{LineCache.size(@tst_file)} lines in file #{@tst_file}"
    end
  end

  describe 'setting breakpoint to incorrect line' do
    before { enter 'break 2' }

    it 'must not create a breakpoint' do
      debug_file('breakpoint') { Byebug.breakpoints.must_be_empty }
    end

    it 'must show an error' do
      debug_file('breakpoint')
      check_error_includes \
        "Line 2 is not a stopping point in file #{@tst_file}"
    end
  end

  describe 'stopping at breakpoint' do
    it 'must stop at the correct line' do
      enter 'break 5', 'cont'
      debug_file('breakpoint') { state.line.must_equal 5 }
    end

    it 'must stop at the correct file' do
      enter 'break 5', 'cont'
      debug_file('breakpoint') { state.file.must_equal @tst_file }
    end

    describe 'show a message' do
      describe 'with full filename' do
        it 'must show a message with full filename' do
          enter 'break 5', 'cont'
          debug_file('breakpoint') { @id = Byebug.breakpoints.first.id }
          check_output_includes "Created breakpoint #{@id} at #{@tst_file}:5"
        end
      end

      describe 'with basename' do
        temporary_change_hash Byebug.settings, :basename, true

        it 'must show a message with basename' do
          enter 'break 5', 'cont'
          debug_file('breakpoint') { @id = Byebug.breakpoints.first.id }
          check_output_includes "Created breakpoint #{@id} at breakpoint.rb:5"
        end
      end
    end
  end

  describe 'reloading source on change' do
    describe 'autoreload not set' do
      temporary_change_hash Byebug.settings, :autoreload, false

      it 'must not reload source' do
        id = nil
        enter ->{ change_line_in_file(@tst_file, 5, ''); 'break 5' },
              ->{ change_line_in_file(@tst_file, 5, 'BreakpointExample.new.b');
              cont }
        debug_file('breakpoint') { id = Byebug.breakpoints.first.id }
        check_output_includes "Created breakpoint #{id} at #{@tst_file}:5"
      end
    end

    describe 'autoreload set' do
      it 'must reload source' do
        enter \
          ->{change_line_in_file(@tst_file, 5, ''); 'break 5'},
          ->{change_line_in_file(@tst_file, 5, 'BreakpointExample.new.b');
            'next'}
        debug_file 'breakpoint'
        check_error_includes \
          "Line 5 is not a stopping point in file #{@tst_file}"
      end
    end
  end

  describe 'set breakpoint in a file' do
    describe 'successfully' do
      before { enter "break #{__FILE__}:3", 'cont' }

      it 'must stop at the correct line' do
        debug_file('breakpoint') { state.line.must_equal 3 }
      end

      it 'must stop at the correct file' do
        debug_file('breakpoint') { state.file.must_equal __FILE__ }
      end
    end

    describe 'when setting breakpoint to unexisted file' do
      before do
        enter 'break asf:324'
        debug_file('breakpoint')
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
      before { enter 'break BreakpointExample#b', 'cont' }

      it 'must stop at the correct line' do
        debug_file('breakpoint') { state.line.must_equal 5 }
      end

      it 'must stop at the correct file' do
        debug_file('breakpoint') { state.file.must_equal __FILE__ }
      end
    end

    describe 'set breakpoint to a class method' do
      before { enter 'break BreakpointExample.a', 'cont' }

      it 'must stop at the correct line' do
        debug_file('breakpoint') { state.line.must_equal 2 }
      end

      it 'must stop at the correct file' do
        debug_file('breakpoint') { state.file.must_equal __FILE__ }
      end
    end

    describe 'set breakpoint to unexisted class' do
      it 'must show an error' do
        enter 'break B.a'
        debug_file('breakpoint')
        check_error_includes 'Unknown class B.'
      end
    end
  end

  describe 'set breakpoint to an invalid location' do
    before { enter 'break foo' }

    it 'must not create a breakpoint' do
      debug_file('breakpoint') { Byebug.breakpoints.must_be_empty }
    end

    it 'must show an error' do
      debug_file('breakpoint')
      check_error_includes 'Invalid breakpoint location: foo.'
    end
  end

  describe 'disabling breakpoints' do
    describe 'successfully' do
      before { enter 'break 5', 'break 6' }

      describe 'short syntax' do
        before { enter ->{ "disable #{Byebug.breakpoints.first.id}" } }

        it 'must have a breakpoint with #enabled? returning false' do
          debug_file('breakpoint') {
            Byebug.breakpoints.first.enabled?.must_equal false }
        end

        it 'must not stop on the disabled breakpoint' do
          enter 'cont'
          debug_file('breakpoint') { state.line.must_equal 6 }
        end
      end

      describe 'full syntax' do
        describe 'with no args' do
          before { enter 'disable breakpoints' }

          it 'must have all breakoints with #enabled? returning false' do
            debug_file('breakpoint') do
              Byebug.breakpoints.first.enabled?.must_equal false
              Byebug.breakpoints.last.enabled?.must_equal false
            end
          end

          it 'must not stop on any disabled breakpoint' do
            enter 'cont'
            debug_file('breakpoint')
            # Obscure assert to check for program termination
            state.proceed.must_equal true
          end
        end

        describe 'with specific breakpoint' do
          before do
            enter ->{ "disable breakpoints #{Byebug.breakpoints.first.id}" }
          end

          it 'must have a breakpoint with #enabled? returning false' do
            debug_file('breakpoint') {
              Byebug.breakpoints.first.enabled?.must_equal false }
          end
        end
      end
    end

    describe 'unsuccesfully' do
      it 'must show an error if syntax is incorrect' do
        enter 'disable'
        debug_file('breakpoint')
        check_error_includes '"disable" must be followed by "display", ' \
                             '"breakpoints" or breakpoint numbers.'
      end

      it 'must show an error if no breakpoints are set' do
        enter 'disable 1'
        debug_file('breakpoint')
        check_error_includes 'No breakpoints have been set.'
      end

      it 'must show an error if a number is not provided as an argument' do
        enter 'break 5', 'disable foo'
        debug_file('breakpoint')
        check_output_includes \
          '"disable breakpoints" argument "foo" needs to be a number.'
      end
    end
  end

  describe 'enabling breakpoints' do
    describe 'successfully' do
      before { enter 'break 5', 'break 6', 'disable breakpoints' }

      describe 'short syntax' do
        before { enter ->{ "enable #{Byebug.breakpoints.first.id}" } }

        it 'must have a breakpoint with #enabled? returning true' do
          debug_file('breakpoint') {
            Byebug.breakpoints.first.enabled?.must_equal true }
        end

        it 'must stop on the enabled breakpoint' do
          enter 'cont'
          debug_file('breakpoint') { state.line.must_equal 5 }
        end
      end

      describe 'full syntax' do
        describe 'with no args' do
          before { enter 'enable breakpoints' }

          it 'must have all breakoints with #enabled? returning true' do
            debug_file('breakpoint') do
              Byebug.breakpoints.first.enabled?.must_equal true
              Byebug.breakpoints.last.enabled?.must_equal true
            end
          end

          it 'must stop on the first breakpoint' do
            enter 'cont'
            debug_file('breakpoint') { state.line.must_equal 5 }
          end

          it 'must stop on the last breakpoint' do
            enter 'cont', 'cont'
            debug_file('breakpoint') { state.line.must_equal 6 }
          end
        end

        describe 'with specific breakpoint' do
          before do
            enter ->{ "enable breakpoints #{Byebug.breakpoints.last.id}" }
          end

          it 'must have a breakpoint with #enabled? returning true' do
            debug_file('breakpoint') {
              Byebug.breakpoints.last.enabled?.must_equal true }
          end

          it 'must stop only on the enabled breakpoint' do
            enter 'cont'
            debug_file('breakpoint') { state.line.must_equal 6 }
          end
        end
      end
    end

    describe 'errors' do
      it 'must show an error if syntax is incorrect' do
        enter 'enable'
        debug_file('breakpoint')
        check_error_includes '"enable" must be followed by "display", ' \
                             '"breakpoints" or breakpoint numbers.'
      end
    end
  end

  describe 'deleting a breakpoint' do
    before { enter 'break 5', ->{"delete #{Byebug.breakpoints.first.id}"},
                   'break 6' }

    it 'must have only one breakpoint' do
      debug_file('breakpoint') { Byebug.breakpoints.size.must_equal 1 }
    end

    it 'must not stop on the disabled breakpoint' do
      enter 'cont'
      debug_file('breakpoint') { state.line.must_equal 6 }
    end
  end

  describe 'Conditional breakpoints' do
    it 'must stop if the condition is true' do
      enter 'break 5 if z == 5', 'break 6', 'cont'
      debug_file('breakpoint') { state.line.must_equal 5 }
    end

    it 'must skip if the condition is false' do
      enter 'break 5 if z == 3', 'break 6', 'cont'
      debug_file('breakpoint') { state.line.must_equal 6 }
    end

    it 'must show an error when conditional syntax is wrong' do
      enter 'break 5 ifa z == 3', 'break 6', 'cont'
      debug_file('breakpoint') { state.line.must_equal 6 }
      check_error_includes \
        'Expecting "if" in breakpoint condition; got: ifa z == 3.'
    end

    describe 'enabling with wrong conditional syntax' do
      before { enter 'break 5',
                     ->{"disable #{Byebug.breakpoints.first.id}"},
                     ->{"cond #{Byebug.breakpoints.first.id} z -=( 3"},
                     ->{"enable #{Byebug.breakpoints.first.id}"} }

      it 'must not enable a breakpoint' do
        debug_file('breakpoint') {
          Byebug.breakpoints.first.enabled?.must_equal false }
      end

      it 'must show an error' do
        debug_file('breakpoint')
        check_error_includes 'Expression "z -=( 3" syntactically incorrect; ' \
                             'breakpoint remains disabled.'
      end
    end

    it 'must show an error if no file or line is specified' do
      enter 'break ifa z == 3', 'break 6', 'cont'
      debug_file('breakpoint') { state.line.must_equal 6 }
      check_error_includes 'Invalid breakpoint location: ifa z == 3.'
    end

    it 'must show an error if expression syntax is invalid' do
      enter 'break if z -=) 3', 'break 6', 'cont'
      debug_file('breakpoint') { state.line.must_equal 6 }
      check_error_includes \
        'Expression "z -=) 3" syntactically incorrect; breakpoint disabled.'
    end
  end

  describe 'Stopping through `byebug` keyword' do
    describe 'when not the last instruction of a method' do
      it 'must stop in the next line' do
        debug_file('breakpoint') { state.line.must_equal 4 }
      end
    end

    describe 'when last instruction of a method' do
      it 'must stop right before returning from the frame' do
        debug_file('breakpoint_deep') { state.line.must_equal 25 }
      end
    end
  end

  describe 'Help' do
    it 'must show info about setting breakpoints when using just "break"' do
      enter 'break', 'cont'
      debug_file 'breakpoint'
      check_output_includes(/b\[reak\] file:line \[if expr\]/)
    end
  end
end
