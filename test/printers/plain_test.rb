module Byebug
  class PrintersPlainTestCase < Minitest::Test
    def yaml_file_path(filename)
      relative_path = "../../../lib/byebug/printers/texts/#{filename}.yml"

      File.expand_path(relative_path, __FILE__)
    end

    def klass
      @klass ||= Printers::Plain
    end

    def printer
      @printer ||= klass.new
    end

    def yaml_plain
      @yaml_plain ||= {
        'foo' => {
          'bar' => 'plain {zee}, {uga} gaa',
          'with_c' => '{arg} bla|c',
          'confirmations' => {
            'okay' => 'Okay?'
          }
        },
        'variable' => { 'variable' => '{key}: {value}' }
      }
    end

    def yaml_base
      @yaml_base ||= {
        'foo' => {
          'bar' => 'base {zee}, {uga} gaa',
          'boo' => '{zee}, gau'
        }
      }
    end

    def setup
      YAML.stubs(:load_file).with(yaml_file_path('plain')).returns(yaml_plain)
      YAML.stubs(:load_file).with(yaml_file_path('base')).returns(yaml_base)
    end

    def test_returns_correctly_translated_string
      assert_equal(
        "plain zuu, aga gaa\n",
        printer.print('foo.bar', zee: 'zuu', uga: 'aga')
      )
    end

    def test_add_yn_to_the_confirmation_strings
      assert_equal('Okay? (y/n) ', printer.print('foo.confirmations.okay'))
    end

    def test_strings_inherited_from_base
      assert_equal("zuu, gau\n", printer.print('foo.boo', zee: 'zuu'))
    end

    def test_error_if_there_is_no_specified_path
      assert_raises(klass::MissedPath) { printer.print('foo.bla') }
    end

    def test_error_if_there_is_no_specified_argument
      assert_raises(klass::MissedArgument) do
        printer.print('foo.bar', zee: 'zuu')
      end
    end

    def test_print_collection
      assert_equal(
        "plain 0, a gaa\nplain 1, b gaa\n",
        printer.print_collection(
          'foo.bar',
          [{ uga: 'a' }, { uga: 'b' }]
        ) do |item, index|
          item.merge(zee: index)
        end
      )
    end

    include Byebug::TestUtils

    def test_columnize_collection_with_modifier_c
      with_setting :width, 30 do
        assert_equal(
          "1 bla  4 bla  7 bla  10 bla\n" \
            "2 bla  5 bla  8 bla\n" \
            '3 bla  6 bla  9 bla',
          printer.print_collection('foo.with_c', (1..10)) { |i, _| { arg: i } }
        )
      end
    end

    def test_print_variables
      assert_equal(%(a: b\nc: d\n), printer.print_variables([%w(a b), %w(c d)]))
    end
  end
end
