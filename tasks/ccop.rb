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
        print('.')
      else
        print('F')
        offenses += 1
      end
    ensure
      FileUtils.rm_f(corrected)
    end
  end

  print "\n#{file_list.size} files inspected, "
  if offenses == 0
    puts "\033[0;32mno offenses detected\033[0m\n"
  else
    puts "\033[0;33m#{offenses} offenses detected.\033[0m" \
         'Run `indent` manually to fix them'
  end
end
