class TestReload < TestDsl::TestCase

  describe 'autoreloading' do
    after { Byebug.settings[:autoreload] = true }

    it 'must notify that automatic reloading is on by default' do
      enter 'reload'
      debug_file 'reload'
      check_output_includes \
        'Source code is reloaded. Automatic reloading is on.'
    end

    it 'must notify that automatic reloading is off if setting changed' do
      enter 'set noautoreload', 'reload'
      debug_file 'reload'
      check_output_includes \
        'Source code is reloaded. Automatic reloading is off.'
    end
  end

  describe 'reloading' do
    after { change_line_in_file(fullpath('reload'), 4, 'a = 4') }
    it 'must reload the code' do
      enter 'break 3', 'cont', 'l 4-4', -> do
        change_line_in_file(fullpath('reload'), 4, 'a = 100')
        'reload'
      end, 'l 4-4'
      debug_file 'reload'
      check_output_includes '4: a = 100'
    end
  end
end
