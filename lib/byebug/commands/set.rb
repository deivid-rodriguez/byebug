module Byebug

  # Mix-in module to setting settings
  module SetFunctions

    def set_setting(setting_name, setting_value, setting_args)
      case setting_name
      when /^args$/
        if defined?(Byebug::BYEBUG_SCRIPT)
          Command.settings[:argv][1..-1] = setting_args
        else
          Command.settings[:argv] = setting_args
        end
      when /^autoirb$/
        Command.settings[:autoirb] = (setting_value ? 1 : 0)
      when /^autolist$/
        Command.settings[:autolist] = (setting_value ? 1 : 0)
      when /^callstyle$/
        if setting_args[0] and ['short', 'long'].include?(setting_args[0])
          Command.settings[:callstyle] = setting_args[0].to_sym
        else
          print "Invalid callstyle. Should be one of: \"short\" or \"long\"\n"
        end
      when /^verbose$/
        Byebug.verbose = setting_value
      when /^histfile$/
        return print 'You need to specify a filename' unless setting_args[0]
        Byebug::History.file = File.expand_path(setting_args[0])
      when /^histsize$/
        return print 'You need to specify the history size' unless setting_args[0]
        Byebug::History.max_size = get_int(setting_args[0], "Set histsize")
      when /^linetrace$/
        Byebug.tracing = setting_value
      when /^listsize$/
        listsize = get_int(setting_args[0], 'Set listsize', 1, nil, 10)
        return unless listsize
        Command.settings[:listsize] = listsize
      when /^width$/
        return unless width = get_int(setting_args[0], 'Set width', 10, nil, 80)
        Command.settings[:width] = width
      when /^post_mortem$/
        if setting_value == true
          Byebug.post_mortem
        else
          Byebug.post_mortem = false
        end
      when /^autoeval|autoreload|autosave|basename|forcestep|fullpath|
             linetrace_plus|testing|stack_on_error$/x
        Command.settings[setting_name.to_sym] = setting_value
      else
        return print "Unknown setting #{@match[1]}.\n"
      end
    end
  end

  # Implements byebug "set" command.
  class SetCommand < Command
    Subcmd2 = Struct.new(:name, :min, :is_bool, :help) unless defined?(Subcmd2)

    Subcommands = [
      ['args'          , 2 , false, 'Set argument list to the program '    \
                                    'being debugged when it is started'       ],
      ['autoeval'      , 5 , true , 'Evaluate every unrecognized command'     ],
      ['autolist'      , 5 , true , 'Execute "list" command on every '     \
                                    'breakpoint'                              ],
      ['autoirb'       , 5 , true , 'Invoke IRB on every stop'                ],
      ['autoreload'    , 5 , true , 'Reload source code when changed'         ],
      ['autosave'      , 5 , true , 'Automatically save command history '  \
                                    'record on exit'                          ],
      ['basename'      , 1 , true , 'Set filename display style'              ],
      ['callstyle'     , 2 , false, 'Set how you want call parameters '    \
                                    'displayed'                               ],
      ['forcestep'     , 2 , true , 'Make sure "next/step" commands always' \
                                    'move to a new line'                      ],
      ['fullpath'      , 2 , true , 'Display full file names in frames'       ],
      ['histfile'      , 5 , false, 'Customize file where history is '      \
                                    'loaded from and saved to. By '         \
                                    'default, .byebug_hist'                   ],
      ['histsize'      , 5 , false, 'Customize maximum number of commands ' \
                                    'that are stored in byebug history '    \
                                    'record. By default, 256'                 ],
      ['linetrace'     , 3 , true , 'Enable line execution tracing'           ],
      ['linetrace_plus', 10, true , 'Set line execution tracing to show'    \
                                    'different lines'                         ],
      ['listsize'      , 3 , false, 'Set number of source lines to list by' \
                                    'default'                                 ],
      ['post_mortem'   , 2 , true , 'Enable post-mortem mode'                 ],
      ['stack_on_error', 1 , true , 'Display stack trace when "eval" '      \
                                    'raises exception'                        ],
      ['testing'       , 2 , false, 'Used when testing byebug'                ],
      ['verbose'       , 1 , true , 'Enable verbose output of TracePoint '  \
                                    'API events is enabled'                   ],
      ['width'         , 1 , false, 'Number of characters per line for '    \
                                    'byebug\'s output'                        ]
    ].map do |name, min, is_bool, help|
      Subcmd2.new(name, min, is_bool, help)
    end unless defined?(Subcommands)

    self.allow_in_control = true

    def regexp
      /^\s* set (?:\s+(.*))? \s*$/x
    end

    def execute
      return print SetCommand.help(nil) if SetCommand.names.include?(@match[0])

      args = @match[1].split(/[ \t]+/)
      try_subcmd = args.shift
      try_subcmd.downcase!
      if try_subcmd =~ /^no/i
        set_on = false
        try_subcmd = try_subcmd[2..-1]
      else
        set_on = true
      end

      subcmd = Command.find(Subcommands, try_subcmd)
      return print "Unknown set command \"#{try_subcmd}\"\n" unless subcmd

      begin
        set_on = get_onoff(args[0]) if subcmd.is_bool and args.size > 0
      rescue RuntimeError
        return
      end

      set_setting(subcmd.name, set_on, args)

      return print "#{show_setting(subcmd.name)}\n"
    end

    class << self
      def names
        %w(set)
      end

      def description
        %{Modifies parts of byebug environment. Boolean values take on, off, 1
          or 0. You can see these environment settings with the "show" command.}
      end
    end
  end

end
