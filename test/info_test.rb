require_relative 'test_helper'

class TestInfo < TestDsl::TestCase
  include Columnize

   describe 'Args info' do
     temporary_change_hash Byebug::Command.settings, :width, 15

     it 'must show info about all args' do
       enter 'break 3', 'cont', 'info args'
       debug_file 'info'
       check_output_includes 'a = "aaaaaaa...', 'b = "b"'
     end
   end

  describe 'Breakpoints info' do
    it 'must show info about all breakpoints' do
      enter 'break 7', 'break 9 if a == b', 'info breakpoints'
      debug_file 'info'
      check_output_includes 'Num Enb What',
                            /\d+ +y   at #{fullpath('info')}:7/,
                            /\d+ +y   at #{fullpath('info')}:9 if a == b/
    end

    it 'must show info about specific breakpoint' do
      enter 'break 7', 'break 9',
            ->{ "info breakpoints #{Byebug.breakpoints.first.id}" }
      debug_file 'info'
      check_output_includes 'Num Enb What', /\d+ +y   at #{fullpath('info')}:7/
      check_output_doesnt_include  /\d+ +y   at #{fullpath('info')}:9/
    end

    it 'must show an error if no breakpoints are found' do
      enter 'info breakpoints'
      debug_file 'info'
      check_output_includes 'No breakpoints.'
    end

    it 'must show an error if no breakpoints are found' do
      enter 'break 7', 'info breakpoints 123'
      debug_file 'info'
      check_output_includes \
        'No breakpoints found among list given.', interface.error_queue
    end

    it 'must show hit count' do
      enter 'break 9', 'cont', 'info breakpoints'
      debug_file 'info'
      check_output_includes \
        /\d+ +y   at #{fullpath('info')}:9/, 'breakpoint already hit 1 time'
    end
  end

  describe 'Display info' do
    it 'must show all display expressions' do
      enter 'display 3 + 3', 'display a + b', 'info display'
      debug_file 'info'
      check_output_includes "Auto-display expressions now in effect:\n" \
                            'Num Enb Expression',
                            '1: y  3 + 3',
                            '2: y  a + b'
    end

    it 'must show a message if there are no display expressions created' do
      enter 'info display'
      debug_file 'info'
      check_output_includes 'There are no auto-display expressions now.'
    end
  end

  describe 'Files info' do
    let(:files) { (LineCache.cached_files + SCRIPT_LINES__.keys).uniq.sort }

    it 'must show all files read in' do
      enter 'info files'
      debug_file 'info'
      check_output_includes files.map { |f| "File #{f}" }
    end

    it 'must show all files read in using "info file" too' do
      enter 'info file'
      debug_file 'info'
      check_output_includes files.map { |f| "File #{f}" }
    end

    it 'must show explicitly loaded files' do
      enter 'info files stat'
      debug_file 'info'
      check_output_includes "File #{fullpath('info')}",
                            LineCache.stat(fullpath('info')).mtime.to_s
    end
  end

  describe 'File info' do
    let(:file)     { fullpath('info') }
    let(:filename) { "File #{file}" }
    let(:lines)    { "#{LineCache.size(file)} lines" }
    let(:mtime)    { LineCache.stat(file).mtime.to_s }
    let(:sha1)     { LineCache.sha1(file) }
    let(:breakpoint_line_numbers) {
      columnize(LineCache.trace_line_numbers(file).to_a.sort,
                Byebug::Command.settings[:width]) }

    it 'must show basic info about the file' do
      enter "info file #{file} basic"
      debug_file 'info'
      check_output_includes filename, lines
      check_output_doesnt_include breakpoint_line_numbers, mtime, sha1
    end

    it 'must show number of lines' do
      enter "info file #{file} lines"
      debug_file 'info'
      check_output_includes filename, lines
      check_output_doesnt_include breakpoint_line_numbers, mtime, sha1
    end

    it 'must show mtime of the file' do
      enter "info file #{file} mtime"
      debug_file 'info'
      check_output_includes filename, mtime
      check_output_doesnt_include lines, breakpoint_line_numbers, sha1
    end

    it 'must show sha1 of the file' do
      enter "info file #{file} sha1"
      debug_file 'info'
      check_output_includes filename, sha1
      check_output_doesnt_include lines, breakpoint_line_numbers, mtime
    end

    it 'must show breakpoints in the file' do
      enter 'break 5', 'break 7', "info file #{file} breakpoints"
      debug_file 'info'
      check_output_includes /Created breakpoint \d+ at #{file}:5/,
                            /Created breakpoint \d+ at #{file}:7/,
                            filename,
                            'breakpoint line numbers:', breakpoint_line_numbers
      check_output_doesnt_include lines, mtime, sha1
    end

    it 'must show all info about the file' do
      enter "info file #{file} all"
      debug_file 'info'
      check_output_includes \
        filename, lines, breakpoint_line_numbers, mtime, sha1
    end

    it 'must not show info about the file if the file is not loaded' do
      enter "info file #{fullpath('info2')} basic"
      debug_file 'info'
      check_output_includes "File #{fullpath('info2')} is not cached"
    end

    it 'must not show any info if the parameter is invalid' do
      enter "info file #{file} blabla"
      debug_file 'info'
      check_output_includes 'Invalid parameter blabla', interface.error_queue
    end
  end

  describe 'Instance variables info' do
    it 'must show instance variables' do
      enter 'break 21', 'cont', 'info instance_variables'
      debug_file 'info'
      check_output_includes '@bla = "blabla"', '@foo = "bar"'
    end
  end

  describe 'Line info' do
    it 'must show the current line' do
      enter 'break 21', 'cont', 'info line'
      debug_file 'info'
      check_output_includes "Line 21 of \"#{fullpath('info')}\""
    end
  end

  describe 'Locals info' do
    temporary_change_hash Byebug::Command.settings, :width, 21

    it 'must show the current local variables' do
      enter 'break 21', 'cont', 'info locals'
      debug_file 'info'
      check_output_includes 'a = "1111111111111...', 'b = 2'
    end

    it 'must fail if local variable doesn\'t respond to #to_s or to #inspect' do
      enter 'break 26', 'cont', 'info locals'
      debug_file 'info'
      check_output_includes '*Error in evaluation*'
    end
  end

  describe 'Program info' do
    it 'must show the initial stop reason' do
      enter 'info program'
      debug_file 'info'
      check_output_includes \
        'It stopped after stepping, next\'ing or initial start.'
    end

    it 'must show the step stop reason' do
      enter 'step', 'info program'
      debug_file 'info'
      check_output_includes \
        'Program stopped.',
        'It stopped after stepping, next\'ing or initial start.'
    end

    it 'must show the breakpoint stop reason' do
      enter 'break 7', 'cont', 'info program'
      debug_file 'info'
      check_output_includes 'Program stopped.', 'It stopped at a breakpoint.'
    end

    it 'must show the catchpoint stop reason' do
      skip('TODO')
    end

    it 'must show the unknown stop reason' do
      enter 'break 7', 'cont',
             ->{ context.stubs(:stop_reason).returns('blabla'); 'info program' }
      debug_file 'info'
      check_output_includes 'Program stopped.', 'unknown reason: blabla'
    end

    it 'must show an error if the program is crashed' do
      skip('TODO')
    end
  end

  describe 'Stack info' do
    it 'must show stack info' do
      enter 'set fullpath', 'break 20', 'cont', 'info stack'
      debug_file 'info'
      check_output_includes /--> #0  InfoExample.a\s+at #{fullpath('info')}:20/,
                                /#1  InfoExample.b\s+at #{fullpath('info')}:30/,
                                /#2  <top \(required\)>\s+at #{fullpath('info')}:36/
    end
  end

  describe 'Global Variables info' do
    it 'must show global variables' do
      enter 'info global_variables'
      debug_file 'info'
      check_output_includes "$$ = #{Process.pid}"
    end
  end

  describe 'Variables info' do
    temporary_change_hash Byebug::Command.settings, :width, 30

    it 'must show all variables' do
      enter 'break 21', 'cont', 'info variables'
      debug_file 'info'
      check_output_includes 'a = "1111111111111111111111...',
                            'b = 2',
                            /self = #<InfoExample:\S+.../,
                            '@bla = "blabla"',
                            '@foo = "bar"'
    end

    it 'must fail if the variable doesn\'t respond to #to_s or to #inspect' do
      enter 'break 26', 'cont', 'info variables'
      debug_file 'info'
      check_output_includes 'a = *Error in evaluation*',
                            /self = #<InfoExample:\S+.../,
                            '@bla = "blabla"',
                            '@foo = "bar"'
    end

    it 'must correctly print variables containing % sign' do
      enter 'break 32', 'cont', 'info variables'
      debug_file 'info'
      check_output_includes 'e = "%.2f"'
    end
  end

  describe 'Help' do
    it 'must show help when typing just "info"' do
      enter 'info', 'cont'
      debug_file 'info'
      check_output_includes /List of "info" subcommands:/
    end
  end

  describe 'Post Mortem' do
    it 'must work in post-mortem mode' do
      enter 'cont', 'info line'
      debug_file 'post_mortem'
      check_output_includes "Line 8 of \"#{fullpath('post_mortem')}\""
    end
  end

end
