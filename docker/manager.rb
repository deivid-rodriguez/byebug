# frozen_string_literal: true

require "net/http"
require "yaml"
require "open3"

module Docker
  #
  # Manages byebug docker images
  #
  class Manager
    VERSIONS = %w[
      2.3.8
      2.4.5
      2.5.3
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

      run(command)
    end

    def test
      command = <<-COMMAND
        docker run --rm -v$(pwd):/byebug #{tag} bash -c 'bin/bundle && bin/rake'
      COMMAND

      print "Testing image #{tag}: #{squish(command)}  "

      run(command)
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

      run("docker push #{tag}")
    end

    class << self
      def build_default
        default_image.build
      end

      def test_default
        default_image.test
      end

      def push_default
        default_image.push
      end

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

      def default_image
        new(version: VERSIONS.last, line_editor: "readline", compiler: "gcc")
      end
    end

    private

    def line_editor_package
      line_editor == "readline" ? "readline-dev" : "libedit-dev"
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

    def run(command)
      output, status = Open3.capture2e(command)

      puts(status ? "✔" : "❌")

      puts output unless status.success?
    end

    def tag
      "deividrodriguez/byebug:#{version}-#{line_editor}-#{compiler}"
    end

    def squish(command)
      command.gsub(/[\n ]+/, " ").strip
    end
  end
end
