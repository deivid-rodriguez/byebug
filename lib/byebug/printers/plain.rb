require 'byebug/printers/base'

module Byebug
  module Printers
    class Plain < Base
      include Columnize

      def print(path, args = {})
        message = translate(locate(path), args)
        tail = parts(path).include?('confirmations') ? ' (y/n) ' : "\n"
        message << tail
      end

      def print_collection(path, collection, &block)
        modifier = get_modifier(path)
        lines = array_of_args(collection, &block).map do |args|
          print(path, args)
        end

        if modifier == 'c'
          columnize(lines.map { |l| l.gsub(/\n$/, '') }, Setting[:width])
        else
          lines.join('')
        end
      end

      def print_variables(variables)
        print_collection('variable.variable', variables) do |(key, value), _|
          value = value.nil? ? 'nil' : value.to_s
          if "#{key} = #{value}".size > Setting[:width]
            key_size = "#{key} = ".size
            value = value[0..Setting[:width] - key_size - 4] + '...'
          end

          { key: key, value: value }
        end
      end

      private

      def get_modifier(path)
        modifier_regexp = /\|(\w+)$/
        modifier_match = locate(path).match(modifier_regexp)
        modifier_match && modifier_match[1]
      end

      def contents_files
        [File.expand_path(File.join('..', 'texts', 'plain.yml'), __FILE__)] +
          super
      end
    end
  end
end
