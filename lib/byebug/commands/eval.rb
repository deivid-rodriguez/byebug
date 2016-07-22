require 'byebug/command'
require 'byebug/helpers/eval'
require 'byebug/helpers/file'

module Byebug
  #
  # Edit a file from byebug's prompt.
  #
  class EvalCommand < Command
    include Helpers::EvalHelper
    include Helpers::FileHelper

    self.allow_in_control = false
    self.allow_in_post_mortem = true

    def self.regexp
      /^\s* eval[?]? \s*$/x
    end

    def self.description
      <<-EOD
        eval[?]

        #{short_description}

        Run the string from the current source code
        about to be run. If the command ends with a "?" and no
        string is given, the following translations occur:

          {if|elsif|unless} expr [then]  => expr
          {until|while} expr [do]        => expr
          return expr                    => expr
          case expr                      => expr
          def fn(params)                 => [params]
          var = expr                     => expr
      EOD
    end

    def self.short_description
      'evaluate current source line'
    end

    def execute
      input = get_line(frame.file, frame.line)
      input = extract_expression(input) if @match[0] =~ /eval[?]/
      puts input
      puts safe_inspect(multiple_thread_eval(input))
    end

    private

    # extract the "expression" part of a line of source code.
    #
    def extract_expression(text)
      if text =~ /^\s*(?:if|elsif|unless)\s+/
        text.gsub!(/^\s*(?:if|elsif|unless)\s+/, '')
        text.gsub!(/\s+then\s*$/, '')
      elsif text =~ /^\s*(?:until|while)\s+/
        text.gsub!(/^\s*(?:until|while)\s+/, '')
        text.gsub!(/\s+do\s*$/, '')
      elsif text =~ /^\s*return\s+/
        # EXPRESION in: return EXPRESSION
        text.gsub!(/^\s*return\s+/, '')
      elsif text =~ /^\s*case\s+/
        # EXPRESSION in: case EXPESSION
        text.gsub!(/^\s*case\s*/, '')
      elsif text =~ /^\s*def\s*.*\(.+\)/
        text.gsub!(/^\s*def\s*.*\((.*)\)/, '[\1]')
      elsif text =~ /^\s*[$@A-Za-z_][A-Za-z0-9_\[\]]*\s*=[^=>]/
        # RHS of an assignment statement.
        text.gsub!(/^\s*[$@A-Za-z_][A-Za-z0-9_\[\]]*\s*=/, '')
      end
      text
    end
  end
end
