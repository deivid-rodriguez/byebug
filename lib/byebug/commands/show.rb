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
        return "Argument list to give program being debugged when it is started is \"#{args}\"."
      when /^autolist$/
        on_off = Command.settings[:autolist] > 0
        return "autolist is #{show_onoff(on_off)}."
      when /^autoeval$/
        on_off = Command.settings[:autoeval]
        return "autoeval is #{show_onoff(on_off)}."
      when /^autoreload$/
        on_off = Command.settings[:autoreload]
        return "autoreload is #{show_onoff(on_off)}."
      when /^autoirb$/
        on_off = Command.settings[:autoirb] > 0
        return "autoirb is #{show_onoff(on_off)}."
      when /^basename$/
        on_off = Command.settings[:basename]
        return "basename is #{show_onoff(on_off)}."
      when /^callstyle$/
        style = Command.settings[:callstyle]
        return "Frame call-display style is #{style}."
      when /^commands(:?\s+(\d+))?$/
        if @state.interface.readline_support?
          s = '';
          args = @match[1].split
          if args[1]
            first_line = args[1].to_i - 4
            last_line  = first_line + 10 - 1
            if first_line > Readline::HISTORY.length
              first_line = last_line = Readline::HISTORY.length
            elsif first_line <= 0
              first_line = 1
            end
            if last_line > Readline::HISTORY.length
              last_line = Readline::HISTORY.length
            end
            i = first_line
            commands = Readline::HISTORY.to_a[first_line..last_line]
          else
            if Readline::HISTORY.length > 10
              commands = Readline::HISTORY.to_a[-10..-1]
              i = Readline::HISTORY.length - 10
            else
              commands = Readline::HISTORY.to_a
              i = 1
            end
          end
          commands.each do |cmd|
            s += ("%5d  %s\n" % [i, cmd])
            i += 1
          end
        else
          s='No readline support'
        end
        return s
      when /^testing$/
        on_off = Command.settings[:testing]
        return "Currently testing byebug is #{show_onoff(on_off)}."
      when /^forcestep$/
        on_off = Command.settings[:forcestep]
        return "force-stepping is #{show_onoff(on_off)}."
      when /^fullpath$/
        on_off = Command.settings[:fullpath]
        return "Displaying frame's full file names is #{show_onoff(on_off)}."
      when /^history(:?\s+(filename|save|size))?$/
        args = @match[1].split
        interface = @state.interface
        if args[1]
          show_save = show_size = show_filename = false
          prefix = false
          if args[1] == "save"
            show_save = true
          elsif args[1] == "size"
            show_size = true
          elsif args[1] == "filename"
            show_filename = true
          end
        else
          show_save = show_size = show_filename = true
          prefix = true
        end
        s = []
        if show_filename
          msg = "#{prefix ? 'filename:' : ''} The command history file is " \
                "#{interface.histfile.inspect}"
          s << msg
        end
        if show_save
          msg = (prefix ? "save: " : "") +
            "Saving of history save is #{show_onoff(interface.history_save)}."
          s << msg
        end
        if show_size
          msg = (prefix ? "size: " : "") +
            "Byebug history size is #{interface.history_length}"
          s << msg
        end
        return s.join("\n")
      when /^linetrace$/
        on_off = Byebug.tracing?
        return "line tracing is #{show_onoff(on_off)}."
      when /^linetrace_plus$/
        if Command.settings[:linetrace_plus]
          return "line tracing style is every line."
        else
          return "line tracing style is different consecutive lines."
        end
      when /^listsize$/
        listlines = Command.settings[:listsize]
        return "Number of source lines to list is #{listlines}."
      when /^post_mortem$/
        on_off = Byebug.post_mortem?
        return "post-mortem mode is #{show_onoff(on_off)}"
      when /^stack_on_error$/
        on_off = Command.settings[:stack_on_error]
        return "Displaying stack trace is #{show_onoff(on_off)}."
      when /^verbose$/
        on_off = Byebug.verbose
        return "Verbose output of TracePoint API events is #{show_onoff(on_off)}."
      when /^version$/
        return "Byebug #{Byebug::VERSION}"
      when /^width$/
        return "width is #{Command.settings[:width]}."
      else
        return "Unknown show subcommand #{setting_name}."
      end
    end
  end

  # Implements byebug "show" command.
  class ShowCommand < Command

    Subcommands = [
      ['args'          , 2 , 'Show argument list to the program being '     \
                             'debugged when it is started'                    ],
      ['autoeval'      , 4 , 'Show whether unrecognized commands are '      \
                             'evaluated'                                      ],
      ['autolist'      , 4 , 'Show whether "list" command is run on stopping' ],
      ['autoirb'       , 4 , 'Show whether IRB is invoked on stopping'        ],
      ['autoreload'    , 4 , 'Show whether source code is reloaded when '   \
                             'changed'                                        ],
      ['basename'      , 1 , 'Show whether basename is used when reporting' \
                             ' files'                                         ],
      ['callstyle'     , 2 , 'Show parameter style used when showing call'  \
                             ' frames'                                        ],
      ['commands'      , 2 , 'Show the history of commands you typed. You ' \
                             'can supply a command number to start with'      ],
      ['forcestep'     , 1 , 'Show whether "next/step" commands are set to' \
                             ' always move to a line'                         ],
      ['fullpath'      , 2 , 'Show whether full paths are displayed in frames'],
      ['history'       , 2 , 'Show command history configurations. '          ],
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

    ShowHistorySubcommands = [
      ['filename', 1, 'Show the filename in which to record command history' ],
      ['save'    , 1, 'Show whether history record should be saved on exit'  ],
      ['size'    , 1, 'Show the size of the command history'                 ]
    ].map do |name, min, help|
      Subcmd.new(name, min, help)
    end unless defined?(SetHistorySubcommands)

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
