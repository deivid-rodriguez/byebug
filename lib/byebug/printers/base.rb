require 'yaml'

module Byebug
  module Printers
    class Base
      class MissedPath < StandardError; end
      class MissedArgument < StandardError; end

      SEPARATOR = "."

      def type
        self.class.name.split("::").last.downcase
      end

      private

        def locate(path)
          result = nil
          contents.each do |_, contents|
            result = parts(path).inject(contents) do |r, part|
              r && r.has_key?(part) ? r[part] : nil
            end
            break if result
          end
          raise MissedPath, "Can't find part path '#{path}'" unless result
          result
        end

        def translate(string, args = {})
          string.gsub(/\|\w+$/, '').gsub(/([^#]?){([^}]*)}/) do # they may contain #{} string interpolation
            key = $2.to_s.to_sym
            raise MissedArgument, "Missed argument #{$2} for '#{string}'" unless args.has_key?(key)
            "#{$1}#{args[key]}"
          end
        end

        def parts(path)
          path.split(SEPARATOR)
        end

        def contents
          @contents ||= contents_files.inject({}) do |hash, filename|
            hash[filename] = YAML.load_file(filename) || {}
            hash
          end
        end

        def array_of_args(collection, &block)
          collection.each.with_index.inject([]) do |array, (item, index)|
            args = block.call(item, index)
            array << args if args
            array
          end
        end

        def contents_files
          [File.expand_path(File.join("..", "texts", "base.yml"), __FILE__)]
        end
    end
  end
end
