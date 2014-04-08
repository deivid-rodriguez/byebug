module Byebug

  # Mix-in module to showing settings
  module ShowFunctions

    def show_setting(setting_name)
      case setting_name
      when /^args$/
        if Command.settings[:argv] and Command.settings[:argv].size > 0
          if defined?(Byebug::BYEBUG_SCRIPT)
            # byebug was called initially. 1st arg is script name.
            args = Command.settings[:argv][1..-1].join(' ')
          else
            # byebug wasn't called initially. 1st arg is not script name.
            args = Command.settings[:argv].join(' ')
          end
        else
          args = ''
        end
        "Argument list to give program being debugged when it is started is \"#{args}\"."
      when /^autolist$/
        "autolist is #{show_onoff(Command.settings[:autolist] > 0)}."
      when /^autoirb$/
        "autoirb is #{show_onoff(Command.settings[:autoirb] > 0)}."
      when /^autosave$/
        "Saving history is #{show_onoff(Command.settings[:autosave])}."
      when /^callstyle$/
        "Frame call-display style is #{Command.settings[:callstyle]}."
      when /^commands(:?\s+(\d+))?$/
        if Command.settings[:autosave]
          history = Byebug::History
          args = @match[1].split
          if args[1]
            size = get_int(args[1], 'show commands', 1, history.max_size)
          end
          size ? history.to_s(size) : history.to_s
        else
          'Not currently saving history. Enable it with "set autosave"'
        end
      when /^testing$/
        "Currently testing byebug is #{show_onoff(Command.settings[:testing])}."
      when /^forcestep$/
        "force-stepping is #{show_onoff(Command.settings[:forcestep])}."
      when /^fullpath$/
        "Displaying frame's full file names is #{show_onoff(Command.settings[:fullpath])}."
      when /^histfile$/
        "The command history file is \"#{Byebug::History.file}\""
      when /^histsize$/
        "Byebug history's maximum size is #{Byebug::History.max_size}"
      when /^linetrace$/
        "line tracing is #{show_onoff(Byebug.tracing?)}."
      when /^linetrace_plus$/
        if Command.settings[:linetrace_plus]
          'line tracing style is every line.'
        else
          'line tracing style is different consecutive lines.'
        end
      when /^listsize$/
        "Number of source lines to list is #{Command.settings[:listsize]}."
      when /^post_mortem$/
        "Post-mortem mode is #{show_onoff(Byebug.post_mortem?)}"
      when /^stack_on_error$/
        "Displaying stack trace is #{show_onoff(Command.settings[:stack_on_error])}."
      when /^verbose$/
        "Verbose output of TracePoint API events is #{show_onoff(Byebug.verbose)}."
      when /^version$/
        "Byebug #{Byebug::VERSION}"
      when /^width$/
        "Width is #{Command.settings[:width]}."
      when /^autoeval|autoreload|basename$/x
        "#{setting_name} is #{show_onoff(Command.settings[setting_name.to_sym])}."
      else
        "Unknown show subcommand #{setting_name}."
      end
    end
  end

  # Implements byebug "show" command.
  class ShowCommand < Command

    Subcommands = [
      ['args'          , 2 , 'Show argument list to the program being '     \
                             'debugged when it is started'                    ],
      ['autoeval'      , 5 , 'Show whether unrecognized commands are '      \
                             'evaluated'                                      ],
      ['autolist'      , 5 , 'Show whether "list" command is run on stopping' ],
      ['autoirb'       , 5 , 'Show whether IRB is invoked on stopping'        ],
      ['autoreload'    , 5 , 'Show whether source code is reloaded when '   \
                             'changed'                                        ],
      ['autosave'      , 5 , 'Show whether command history is '             \
                             'automatically saved on exit'                    ],
      ['basename'      , 1 , 'Show whether basename is used when reporting' \
                             ' files'                                         ],
      ['callstyle'     , 2 , 'Show parameter style used when showing call'  \
                             ' frames'                                        ],
      ['commands'      , 2 , 'Show the history of commands you typed. You ' \
                             'can supply a command number to start with'      ],
      ['forcestep'     , 1 , 'Show whether "next/step" commands are set to' \
                             ' always move to a line'                         ],
      ['fullpath'      , 2 , 'Show whether full paths are displayed in frames'],
      ['histfile'      , 5 , 'File where byebug save history of commands'     ],
      ['histsize'      , 5 , 'Maximum number of commands stored in '        \
                             'byebug\'s history'                              ],
      ['linetrace'     , 3 , 'Show line execution tracing status'             ],
      ['linetrace_plus', 10, 'Show whether different consecutive lines are' \
                             ' shown in tracing'                              ],
      ['listsize'      , 3 , 'Show number of source lines to list by default' ],
      ['post_mortem'   , 3 , 'Show whether we should go into post-mortem '  \
                             'debugging on an uncaught exception'             ],
      ['stack_on_error', 1 , 'Show whether a stack trace is displayed when' \
                             ' "eval" raises an exception'                    ],
      ['verbose'       , 4 , 'Show whether verbose output for debugging '   \
                             'byebug itself is enabled'                       ],
      ['version'       , 1 , 'Show byebug\'s version'                         ],
      ['width'         , 1 , 'Show the number of characters per line for '  \
                             'byebug'                                         ]
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(Subcommands)

    self.allow_in_control = true

    def regexp
      /^\s* show (?:\s+(.+))? \s*$/x
    end

    def execute
      return print ShowCommand.help(nil) unless @match[1]

      args = @match[1].split(/[ \t]+/)
      param = args.shift
      subcmd = Command.find(Subcommands, param)
      if subcmd
        print "%s\n" % show_setting(subcmd.name)
      else
        print "Unknown show command #{param}\n"
      end
    end

    class << self
      def names
        %w(show)
      end

      def description
        %{Generic command for showing things about byebug.}
      end
    end

  end
end
