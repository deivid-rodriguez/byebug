module Byebug

  module EvalFunctions
    def run_with_binding
      binding = @state.context ? get_binding : TOPLEVEL_BINDING
      $__dbg_interface = @state.interface
      eval(<<-EOC, binding)
        __dbg_verbose_save=$VERBOSE; $VERBOSE=false
        def dbg_print(*args)
          $__dbg_interface.print(*args)
        end
        remove_method :puts if self.respond_to?(:puts) &&
          defined?(remove_method)
        def dbg_puts(*args)
          $__dbg_interface.print(*args)
          $__dbg_interface.print("\n")
        end
        $VERBOSE=__dbg_verbose_save
      EOC
      yield binding
    ensure
      $__dbg_interface = nil
    end
  end

  class EvalCommand < Command
    self.allow_in_control = true

    register_setting_get(:autoeval) do
      EvalCommand.unknown
    end
    register_setting_set(:autoeval) do |value|
      EvalCommand.unknown = value
    end

    # Set default value
    Command.settings[:autoeval] = true

    def match(input)
      @input = input
      super
    end

    def regexp
      /^\s*(p|e(?:val)?)\s+/
    end

    def execute
      expr = @match ? @match.post_match : @input
      run_with_binding do |b|
        print "#{debug_eval(expr, b).inspect}\n"
      end
    end

    class << self
      def names
        %w(p eval)
      end

      def description
        %{
          (p|e[val]) expression\tevaluate expression and print its value
          * NOTE - to turn on autoeval, use 'set autoeval'
         }
      end
    end
  end

  class PPCommand < Command
    self.allow_in_control = true

    def regexp
      /^\s*pp\s+/
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        PP.pp(debug_eval(@match.post_match, b), out)
      end
      print out.string
    rescue
      out.puts $!.message
    end

    class << self
      def names
        %w(pp)
      end

      def description
        %{
          pp expression\tevaluate expression and pretty-print its value
        }
      end
    end
  end

  class PutLCommand < Command
    include Columnize
    self.allow_in_control = true

    def regexp
      /^\s*putl\s+/
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        vals = debug_eval(@match.post_match, b)
        if vals.is_a?(Array)
          vals = vals.map{|item| item.to_s}
          print "#{columnize(vals, Command.settings[:width])}\n"
        else
          PP.pp(vals, out)
          print out.string
        end
      end
    rescue
      out.puts $!.message
    end

    class << self
      def names
        %w(putl)
      end

      def description
        %{
          putl expression\tevaluate expression, an array, and columnize its value
        }
      end
    end
  end

  class PSCommand < Command
    include Columnize
    self.allow_in_control = true

    include EvalFunctions

    def regexp
      /^\s*ps\s+/
    end

    def execute
      out = StringIO.new
      run_with_binding do |b|
        vals = debug_eval(@match.post_match, b)
        if vals.is_a?(Array)
          vals = vals.map{|item| item.to_s}
          print "#{columnize(vals.sort!, Command.settings[:width])}\n"
        else
          PP.pp(vals, out)
          print out.string
        end
      end
    rescue
      out.puts $!.message
    end

    class << self
      def names
        %w(ps)
      end

      def description
        %{
          ps expression\tevaluate expression, an array, sort and columnize its value
        }
      end
    end
  end

end
