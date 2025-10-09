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
      3.2.9
      3.3.9
    ].freeze

    COMPILERS = %w[
      gcc
      clang
    ].freeze

    attr_reader :version, :compiler

    def initialize(version:, compiler:)
      @version = version
      @compiler = compiler
    end

    def login
      self.class.login
    end

    def build
      command = <<-COMMAND
        docker build \
          --tag "#{tag}" \
          --build-arg "ruby_download_url=#{download_url}" \
          --build-arg "ruby_download_sha256=#{download_sha256}" \
          --build-arg "compiler=#{compiler}" \
          --file "docker/Dockerfile" \
          .
      COMMAND

      print "Building image #{tag} via `#{squish(command)}`... "

      run(command)
    end

    def test
      command = <<-COMMAND
        docker run --rm -v$(pwd):/byebug #{tag} bash -c 'bin/setup.sh && bin/rake'
      COMMAND

      print "Testing image #{tag}: #{squish(command)}  "

      run(command)
    end

    def push
      print "Pushing image #{tag}... "

      run("docker push #{tag}")
    end

    class << self
      def build_default
        for_last_version_variants(&:build)
      end

      def test_default
        for_last_version_variants(&:test)
      end

      def push_default
        login

        for_last_version_variants(&:push)
      end

      def build_all
        for_all_images(&:build)
      end

      def test_all
        for_all_images(&:test)
      end

      def push_all
        login

        for_all_images(&:push)
      end

      def release_info
        @release_info ||= YAML.safe_load(
          Net::HTTP.get(URI.parse(releases_url)),
          permitted_classes: [Date]
        )
      end

      def run(*command)
        output, status = Open3.capture2e(*command)

        success = status.success?

        puts(success ? "✔" : "❌")

        return if success

        puts output
        abort
      end

      def login
        command = %W[
          docker
          login
          -u
          deividrodriguez
          -p
          #{ENV['DOCKER_PASS']}
        ]

        print "Logging in to dockerhub... "

        run(*command)
      end

      private

      def releases_url
        "https://raw.githubusercontent.com/ruby/www.ruby-lang.org/master/_data/releases.yml"
      end

      def for_all_images(&block)
        VERSIONS.each do |version|
          for_variants_of(version, &block)
        end
      end

      def for_last_version_variants(&block)
        for_variants_of(VERSIONS.last, &block)
      end

      def for_variants_of(version)
        COMPILERS.each do |compiler|
          manager = new(
            version: version,
            compiler: compiler
          )

          yield(manager)
        end
      end
    end

    private

    def download_url
      if version == "head"
        "#{download_url_base}/snapshot.tar.xz"
      else
        "#{download_url_base}/#{abi_version}/ruby-#{version}.tar.xz"
      end
    end

    def abi_version
      version.split(".")[0..1].join(".")
    end

    def download_url_base
      "https://cache.ruby-lang.org/pub/ruby"
    end

    def release_info
      self.class.release_info
    end

    def download_sha256
      version_info = release_info.find { |entry| entry["version"] == version }
      return unless version_info

      version_info["sha256"]["xz"]
    end

    def run(*command)
      self.class.run(*command)
    end

    def tag
      "deividrodriguez/byebug:#{version}-#{compiler}"
    end

    def squish(command)
      command.gsub(/[\n ]+/, " ").strip
    end
  end
end
