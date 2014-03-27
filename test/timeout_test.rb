class TestTimeout < MiniTest::Spec

  it 'call to "Timeout::timeout" after "Byebug.start" does not raise' do
    Byebug.start do
      Timeout::timeout(60) {}
    end
  end

end
