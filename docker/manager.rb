# frozen_string_literal: true

require "net/http"
require "yaml"

module Docker
  #
  # Manages byebug docker images
  #
  class Manager
    VERSIONS = %w[
      2.3.7
      2.4.4
      2.5.1
    ].freeze

    LINE_EDITORS = %w[
      readline
      libedit
    ].freeze

    COMPILERS = %w[
      gcc
      clang
    ].freeze

    attr_reader :version, :line_editor, :compiler

    def initialize(version:, line_editor:, compiler:)
      @version = version
      @line_editor = line_editor
      @compiler = compiler
    end

    def build
      command = <<-COMMAND
        docker build \
          --tag "#{tag}" \
          --build-arg "ruby_version=#{version}" \
          --build-arg "ruby_download_sha256=#{sha256}" \
          --build-arg "compiler=#{compiler}" \
          --build-arg "line_edit_lib=#{line_editor_package}" \
          --build-arg "line_edit_config=#{line_editor_configure_flag}" \
          --file "docker/Dockerfile" \
          .
      COMMAND

      print "Building image #{tag}: #{squish(command)}  "

      status = system(command, out: File::NULL)

      puts(status ? "✔" : "❌")
    end

    def test
      command = <<-COMMAND
        docker run --rm -v$(pwd):/byebug #{tag} bash -c ' bin/bundle && bin/rake'
      COMMAND

      print "Testing image #{tag}: #{squish(command)}  "

      status = system(command, out: File::NULL, err: File::NULL)

      puts(status ? " ✔" : " ❌")
    end

    def push
      print "Pushing image #{tag}... "

      login_cmd = %W[
        docker
        login
        -u
        #{ENV['DOCKER_USER']}
        -p
        #{ENV['DOCKER_PASS']}
      ]

      unless system(*login_cmd, out: File::NULL, err: File::NULL)
        puts "❌"
        return
      end

      pushed = system <<-COMMAND, out: File::NULL
        docker push #{tag}
      COMMAND

      puts pushed ? "✔" : "❌"
    end

    class << self
      def build_all
        for_all_images(&:build)
      end

      def test_all
        for_all_images(&:test)
      end

      def push_all
        for_all_images(&:push)
      end

      def release_info
        @release_info ||= YAML.safe_load(
          Net::HTTP.get(URI.parse(releases_url)),
          [Date]
        )
      end

      private

      def releases_url
        "https://raw.githubusercontent.com/ruby/www.ruby-lang.org/master/_data/releases.yml"
      end

      def for_all_images
        VERSIONS.each do |version|
          COMPILERS.each do |compiler|
            LINE_EDITORS.each do |line_editor|
              manager = new(
                version: version,
                line_editor: line_editor,
                compiler: compiler
              )

              yield(manager)
            end
          end
        end
      end
    end

    private

    def line_editor_package
      line_editor == "readline" ? "libreadline-dev" : "libedit-dev"
    end

    def line_editor_configure_flag
      line_editor == "readline" ? "" : "--enable-libedit"
    end

    def release_info
      self.class.release_info
    end

    def sha256
      release_info.find { |entry| entry["version"] == version }["sha256"]["xz"]
    end

    def tag
      "deividrodriguez/byebug:#{version}-#{line_editor}-#{compiler}"
    end

    def squish(command)
      command.gsub(/[\n ]+/, " ").strip
    end
  end
end
