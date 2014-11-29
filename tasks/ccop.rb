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

desc 'Enforces code style in the C extension using indent'
task :ccop do
  puts 'Running CCop...'

  file_list = Dir['ext/byebug/*.c']
  puts "Inspecting #{file_list.size} files"

  offenses = 0
  file_list.each do |file|
    corrected = "#{file}_corrected"
    begin
      system("indent #{file} -o #{corrected}")
      if FileUtils.compare_file(file, corrected)
        print(green('.'))
      else
        print(red('F'))
        offenses += 1
      end
    ensure
      FileUtils.rm_f(corrected)
    end
  end

  print "\n#{file_list.size} files inspected, "
  if offenses == 0
    puts green('no offenses detected')
  else
    puts red("#{offenses} offenses detected.") + ' Run `indent` to fix them'
  end
end
