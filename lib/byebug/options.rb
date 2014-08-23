module Byebug
  #
  # Set of options that byebug's script accepts.
  #
  class Options
    def self.parse
      Slop.parse!(strict: true) do
        banner <<-EOB.gsub(/^ {8}/, '')

          byebug #{Byebug::VERSION}

          Usage: byebug [options] <script.rb> -- <script.rb parameters>
        EOB

        on :d, :debug, 'Set $DEBUG=true' do
          $DEBUG = true
        end

        on :I, :include=, 'Add to $LOAD_PATH', as: Array, delimiter: ':' do |l|
          $LOAD_PATH.push(l).flatten!
        end

        on :q, :quit, 'Quit when script finishes', default: true

        on :s, :stop, 'Stop when script is loaded', default: true

        on :x, :rc, 'Run byebug initialization file', default: true

        on :m, :'post-mortem', 'Run byebug in post-mortem mode', default: false

        on :r, :require=, 'Require library before script' do |name|
          require name
        end

        on :R, :remote=, '[HOST:]PORT for remote debugging',
           as: Array, delimiter: ':', limit: 2

        on :t, :trace, 'Turn on line tracing'

        on :v, :version, 'Print program version'

        on :h, :help, 'Display this message'
      end
    end
  end
end
