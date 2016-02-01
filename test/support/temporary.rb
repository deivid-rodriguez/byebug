module Byebug
  #
  # Some custom matches for changing stuff temporarily during tests
  #
  module TestTemporary
    #
    # Yields a block using temporary values for command line program name and
    # command line arguments.
    #
    # @param program_name [String] New value for the program name
    # @param *args [Array] New value for the program arguments
    #
    def with_command_line(program_name, *args)
      original_program_name = $PROGRAM_NAME
      original_argv = $ARGV
      $PROGRAM_NAME = program_name
      $ARGV.replace(args)

      yield
    ensure
      $PROGRAM_NAME = original_program_name
      $ARGV.replace(original_argv)
    end

    #
    # Yields a block using a temporary value for a setting
    #
    # @param key [Symbol] Setting key
    # @param value [Object] Temporary value for the setting
    #
    def with_setting(key, value)
      original_value = Setting[key]
      Setting[key] = value

      yield
    ensure
      Setting[key] = original_value
    end

    #
    # Temporary creates a new file a yields it to the passed block
    #
    def with_new_tempfile(content)
      file = Tempfile.new('foo')
      file.write(content)
      file.close

      yield(file.path)
    ensure
      file.close
      file.unlink
    end

    #
    # Changes global rc file to point to the specified file, runs the block and
    # restores the old config afterwards.
    #
    def with_init_file(name)
      old_init_file = Byebug.init_file
      Byebug.init_file = name

      yield
    ensure
      Byebug.init_file = old_init_file
    end

    #
    # Creates a file, yields the block and deletes the file afterwards
    #
    # @param name [String] Name for the file
    # @param content [String] Content for the file
    #
    def with_new_file(name, content)
      File.open(name, 'w') { |f| f.write(content) }

      yield
    ensure
      File.delete(name)
    end
  end
end
