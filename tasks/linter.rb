# frozen_string_literal: true

#
# Common stuff for a linter
#
module LinterMixin
  def run
    offenses = []

    applicable_files.each do |file|
      if clean?(file)
        print "."
      else
        offenses << file
        print "F"
      end
    end

    print "\n"

    return if offenses.empty?

    raise failure_message_for(offenses)
  end

  private

  def failure_message_for(offenses)
    msg = "#{self.class.name} detected offenses. "

    msg += if respond_to?(:fixing_cmd)
             "Run `#{fixing_cmd(offenses)}` to fix them."
           else
             "Affected files: #{offenses.join(' ')}"
           end

    msg
  end
end

#
# Lints C files
#
class CLangFormatLinter
  include LinterMixin

  def applicable_files
    Dir.glob("ext/byebug/*.[ch]")
  end

  def fixing_cmd(offenses)
    "clang-format-5.0 -i #{offenses.join(' ')} -style=file"
  end

  def clean?(file)
    linted, status = Open3.capture2("clang-format-5.0 #{file} -style=file")

    status.success? && linted == File.read(file)
  end
end

#
# Lints executability of files
#
class ExecutableLinter
  include LinterMixin

  def applicable_files
    Open3.capture2("git ls-files")[0].split
  end

  def clean?(file)
    in_exec_folder = !(%r{(exe|bin)/} =~ file).nil?
    executable = File.executable?(file)

    (in_exec_folder && executable) || (!in_exec_folder && !executable)
  end
end

#
# Checks no tabs in source code
#
class TabLinter
  include LinterMixin

  def applicable_files
    Open3.capture2("git ls-files")[0].split
  end

  def clean?(file)
    relative_path = Pathname.new(__FILE__).relative_path_from(Pathname.new(File.dirname(__dir__))).to_s

    file == relative_path || !File.read(file, encoding: Encoding::UTF_8).include?("	")
  end
end

#
# Checks trailing whitespace
#
class TrailingWhitespaceLinter
  include LinterMixin

  def applicable_files
    Open3.capture2("git ls-files")[0].split
  end

  def clean?(file)
    File.read(file, encoding: Encoding::UTF_8) !~ / +$/
  end
end
