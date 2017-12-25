# frozen_string_literal: true

require 'net/http'
require 'yaml'

module Docker
  #
  # Manages byebug docker images
  #
  class Manager
    VERSIONS = %w[
      2.2.9
      2.3.6
      2.4.3
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
      print "Building image #{tag}... "

      status = system <<-COMMAND, out: File::NULL
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

      puts(status ? '✔' : '❌')
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
        puts '❌'
        return
      end

      pushed = system <<-COMMAND, out: File::NULL
        docker push #{tag}
      COMMAND

      puts pushed ? '✔' : '❌'
    end

    class << self
      def build_all
        for_all_images(&:build)
      end

      def push_all
        for_all_images(&:push)
      end

      def release_info
        @release_info ||= YAML.safe_load(
          Net::HTTP.get(
            URI.parse('https://raw.githubusercontent.com/ruby/www.ruby-lang.org/master/_data/releases.yml')
          ),
          [Date]
        )
      end

      private

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
      line_editor == 'readline' ? 'libreadline-dev' : 'libedit-dev'
    end

    def line_editor_configure_flag
      line_editor == 'readline' ? '' : '--enable-libedit'
    end

    def release_info
      self.class.release_info
    end

    def sha256
      release_info.find { |entry| entry['version'] == version }['sha256']['xz']
    end

    def tag
      "deividrodriguez/byebug:#{version}-#{line_editor}-#{compiler}"
    end
  end
end
