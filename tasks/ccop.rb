#
# ASCII sequence for green
#
def green(string)
  "\033[0;32m#{string}\033[0m"
end

#
# ASCII sequence for red
#
def red(string)
  "\033[0;33m#{string}\033[0m"
end

#
# Checks whether +file+ is compliant with our c-style guidelines using the
# `indent` utility.
#
def c_compliant?(file)
  corrected = "#{file}_corrected"

  status = system("indent #{file} -o #{corrected}")
  return nil if status.nil?

  return false unless FileUtils.compare_file(file, corrected)

  return true
ensure
  FileUtils.rm_f(corrected)
end

desc 'Enforces code style in the C extension using indent'
task :ccop do
  puts "Checking code style in Byebug's C extension..."

  file_list = Dir['ext/byebug/*.c']
  puts "Inspecting #{file_list.size} files"

  offenses = 0
  file_list.each do |file|
    case c_compliant?(file)
    when nil
      fail('Error. Is `indent` installed?')
    when true
      print green('.')
    when false
      offenses += 1
      print red('F')
    end
  end

  print "\n#{file_list.size} files inspected, "
  if offenses == 0
    puts green('no offenses detected')
  else
    puts red("#{offenses} offenses detected.") +
      ' Run `indent ext/byebug/*.c` to fix them'
  end
end
