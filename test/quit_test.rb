class TestQuit < TestDsl::TestCase
  it 'must quit if user confirmed' do
    Byebug::QuitCommand.any_instance.expects(:exit!)
    enter 'quit', 'y'
    debug_file 'quit'
    check_output_includes 'Really quit? (y/n)', interface.confirm_queue
  end

  it 'must not quit if user didn\'t confirm' do
    Byebug::QuitCommand.any_instance.expects(:exit!).never
    enter 'quit', 'n'
    debug_file 'quit'
    check_output_includes 'Really quit? (y/n)', interface.confirm_queue
  end

  it 'must quit immediatly if used with !' do
    Byebug::QuitCommand.any_instance.expects(:exit!)
    enter 'quit!'
    debug_file 'quit'
    check_output_doesnt_include 'Really quit? (y/n)', interface.confirm_queue
  end

  it 'must quit immediatly if used with "unconditionally"' do
    Byebug::QuitCommand.any_instance.expects(:exit!)
    enter 'quit unconditionally'
    debug_file 'quit'
    check_output_doesnt_include 'Really quit? (y/n)', interface.confirm_queue
  end

  it 'must finalize interface before quitting' do
    Byebug::QuitCommand.any_instance.stubs(:exit!)
    interface.expects(:finalize)
    enter 'quit!'
    debug_file 'quit'
  end

  it 'must quit if used "exit" alias' do
    Byebug::QuitCommand.any_instance.expects(:exit!)
    enter 'exit!'
    debug_file 'quit'
  end
end
