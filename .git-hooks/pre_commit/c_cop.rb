#
# Custom pre-commit hook to check C-code style
#
module Overcommit
  module Hook
    module PreCommit
      #
      # Inherit from base hook
      #
      class CCop < Base
        #
        # Implement overcommit's interface
        #
        def run
          missing_requirements = check_for_executable
          return [:fail, missing_requirements] if missing_requirements

          offenses = 0
          applicable_files.each do |file|
            res = execute(command, args: [file])

            unchanged = res.success? && File.read(file) == res.stdout

            offenses += 1 unless unchanged
          end

          return :pass if offenses.zero?

          file_list = applicable_files.join(' ')
          fixing_command = "#{command.join(' ')} -i #{file_list}"
          [:fail, "#{offenses} errors found. Run `#{fixing_command}`"]
        end
      end
    end
  end
end
