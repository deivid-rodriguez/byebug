module SaveTest
  class SaveTestCase < TestDsl::TestCase
    before do
      @example = -> do
        byebug
        a = 2
        a = 3
      end
    end

    describe 'successful saving' do
      let(:file_name) { 'save_output.txt' }
      let(:file_contents) { File.read(file_name) }
      before do
        enter 'break 2', 'break 3 if true', 'catch NoMethodError',
              'display 2 + 3', 'display 5 + 6', "save #{file_name}"
        debug_proc(@example)
      end
      after do
        File.delete(file_name)
      end

      it 'must save usual breakpoints' do
        file_contents.must_include "break #{__FILE__}:2"
      end

      it 'must save conditinal breakpoints' do
        file_contents.must_include "break #{__FILE__}:3 if true"
      end

      it 'must save catchpoints' do
        file_contents.must_include 'catch NoMethodError'
      end

      it 'must save displays' do
        file_contents.must_include 'display 2 + 3'
      end

      describe 'saving settings' do
        it 'must save autoeval' do
          file_contents.must_include 'set autoeval true'
        end

        it 'must save basename' do
          file_contents.must_include 'set basename false'
        end

        it 'must save testing' do
          file_contents.must_include 'set testing true'
        end

        it 'must save autolist' do
          file_contents.must_include 'set autolist true'
        end

        it 'must save autoirb' do
          file_contents.must_include 'set autoirb false'
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
        debug_proc(@example)
        file_contents.must_include 'set autoirb'
      end

      it 'must show a message where the file is saved' do
        enter 'save'
        debug_proc(@example)
        check_output_includes "Saved to '#{interface.restart_file}'"
      end
    end
  end
end
