module ReloadTest
  class ReloadTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 6
        a = 7
        a = 8
        a = 9
        a = 10
      end
    end

    describe 'autoreloading' do
      after { Byebug::Setting[:autoreload] = true }

      it 'must notify that automatic reloading is on by default' do
        enter 'reload'
        debug_proc(@example)
        check_output_includes \
          'Source code is reloaded. Automatic reloading is on.'
      end

      it 'must notify that automatic reloading is off if setting changed' do
        enter 'set noautoreload', 'reload'
        debug_proc(@example)
        check_output_includes \
          'Source code is reloaded. Automatic reloading is off.'
      end
    end

    describe 'reloading' do
      after { change_line_in_file(__FILE__, 8, '        a = 8') }

      it 'must reload the code' do
        enter 'break 7', 'cont', 'l 8-8',
          -> { change_line_in_file(__FILE__, 8, '        a = 100'); 'reload' },
          'l 8-8'
        debug_proc(@example)
        check_output_includes '8:         a = 100'
      end
    end
  end
end
