FROM buildpack-deps:stretch

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo "install: --no-document"; \
    echo "update: --no-document"; \
  } >> /usr/local/etc/gemrc

ARG ruby_version=
ARG ruby_download_sha256=
ARG line_edit_lib=
ARG line_edit_config=
ARG compiler=

ENV CC $compiler

RUN set -ex \
  \
  && baseDeps=" \
    $compiler \
  " \
  && buildOnlyDeps=" \
    libssl1.0-dev \
    $line_edit_lib \
    ruby \
  " \
  && apt-get update \
  && apt-get install -y --no-install-recommends $baseDeps $buildOnlyDeps \
  && rm -rf /var/lib/apt/lists/* \
  \
  && wget -O ruby.tar.xz "https://cache.ruby-lang.org/pub/ruby/${ruby_version%.*}/ruby-$ruby_version.tar.xz" \
  && echo "$ruby_download_sha256 *ruby.tar.xz" | sha256sum -c - \
  \
  && mkdir -p /usr/src/ruby \
  && tar -xJf ruby.tar.xz -C /usr/src/ruby --strip-components=1 \
  && rm ruby.tar.xz \
  \
  && cd /usr/src/ruby \
  \
  && autoconf \
  && gnuArch="$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)" \
  && ./configure \
    --build="$gnuArch" \
    --disable-install-doc \
    $line_edit_config \
    --enable-shared \
  && make -j "$(nproc)" \
  && make install \
  \
  && apt-get purge -y --auto-remove $buildOnlyDeps \
  && cd / \
  && rm -r /usr/src/ruby \
  \
  && gem update --system 2.7.7 \
  && rm -r /root/.gem

RUN apt-get update && apt-get install -y --no-install-recommends \
  clang-format \
  shellcheck

ENV BUNDLE_SILENCE_ROOT_WARNING=1

RUN TEST_REPORTER_URL=https://codeclimate.com/downloads/test-reporter/test-reporter-0.6.0-linux-amd64 \
  && wget -O /usr/local/bin/cc-test-reporter $TEST_REPORTER_URL \
  && chmod +x /usr/local/bin/cc-test-reporter

WORKDIR /byebug
