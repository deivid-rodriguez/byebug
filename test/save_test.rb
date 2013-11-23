class TestSave < TestDsl::TestCase

  describe 'successful saving' do
    let(:file_name) { 'save_output.txt' }
    let(:file_contents) { File.read(file_name) }
    before do
      enter 'break 2', 'break 3 if true', 'catch NoMethodError',
            'display 2 + 3', 'display 5 + 6', "save #{file_name}"
      debug_file 'save'
    end
    after do
      File.delete(file_name)
    end

    it 'must save usual breakpoints' do
      file_contents.must_include "break #{fullpath('save')}:2"
    end

    it 'must save conditinal breakpoints' do
      file_contents.must_include "break #{fullpath('save')}:3 if true"
    end

    it 'must save catchpoints' do
      file_contents.must_include 'catch NoMethodError'
    end

    it 'must save displays' do
      file_contents.must_include 'display 2 + 3'
    end

    describe 'saving settings' do
      it 'must save autoeval' do
        file_contents.must_include 'set autoeval on'
      end

      it 'must save basename' do
        file_contents.must_include 'set basename off'
      end

      it 'must save testing' do
        file_contents.must_include 'set testing on'
      end

      it 'must save autolist' do
        file_contents.must_include 'set autolist on'
      end

      it 'must save autoirb' do
        file_contents.must_include 'set autoirb off'
      end
    end

    it 'must show a message about successful saving' do
      check_output_includes "Saved to '#{file_name}'"
    end
  end

  describe 'without filename' do
    let(:file_contents) { File.read(interface.restart_file) }
    after { FileUtils.rm(interface.restart_file) }

    it 'must fabricate a filename if not provided' do
      enter 'save'
      debug_file 'save'
      file_contents.must_include 'set autoirb'
    end

    it 'must show a message where the file is saved' do
      enter 'save'
      debug_file 'save'
      check_output_includes "Saved to '#{interface.restart_file}'"
    end
  end
end
