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
            res = execute([required_executable, file, '-o', "#{file}_"])

            unchanged = FileUtils.compare_file(file, "#{file}_") if res.success?

            offenses += 1 unless unchanged

            FileUtils.rm_f("#{file}_")
          end

          return :pass if offenses == 0

          file_list = applicable_files.join(' ')
          [:fail, "#{offenses} errors found. Run `indent #{file_list}`"]
        end
      end
    end
  end
end
