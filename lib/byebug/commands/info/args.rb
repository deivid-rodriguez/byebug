module Byebug
  #
  # Reopens the +info+ command to define the +args+ subcommand
  #
  class InfoCommand < Command
    #
    # Information about arguments of the current method/block
    #
    class ArgsSubcommand < Command
      def regexp
        /^\s* a(?:rgs)? \s*$/x
      end

      def execute
        locals = @state.context.frame_locals
        args = @state.context.frame_args
        return if args == [[:rest]]

        args.map do |_, name|
          s = "#{name} = #{locals[name].inspect}"
          s[Setting[:width] - 3..-1] = '...' if s.size > Setting[:width]
          puts s
        end
      end

      def short_description
        'Information about arguments of the current method/block'
      end

      def description
        <<-EOD
          inf[o] a[args]

          #{short_description}
        EOD
      end
    end
  end
end
