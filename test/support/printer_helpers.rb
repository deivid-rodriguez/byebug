module Byebug
  module PrinterHelpers
    def yaml_file_path(filename)
      File.expand_path(
        File.join('..', '..', '..', 'lib', 'byebug',
                  'printers', 'texts', "#{filename}.yml"),
        __FILE__
      )
    end
  end
end
