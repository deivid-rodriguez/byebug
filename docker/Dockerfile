FROM alpine:3.16

# skip installing gem documentation
RUN mkdir -p /usr/local/etc \
  && { \
    echo "install: --no-document"; \
    echo "update: --no-document"; \
  } >> /usr/local/etc/gemrc

ARG ruby_download_url=
ARG ruby_download_sha256=
ARG compiler=

ENV CC=$compiler

RUN set -ex \
  \
  && baseDeps=" \
    bash \
    ca-certificates \
    cmake \
    clang \
    clang-extra-tools \
    gcc \
    libc-dev \
    libffi-dev \
    libressl-dev \
    make \
    yaml-dev \
  " \
  && buildOnlyDeps=" \
    autoconf \
    bison \
    build-base \
    bzip2-dev \
    dpkg \
    dpkg-dev \
    gdbm-dev \
    glib-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    ncurses-dev \
    openssl \
    openssl-dev \
    ruby \
  " \
  && apk add --no-cache --virtual .ruby-builddeps $baseDeps $buildOnlyDeps \
  \
  && wget -O ruby.tar.xz "$ruby_download_url" \
  && if [ "$ruby_download_sha256" != "" ]; then echo "$ruby_download_sha256 *ruby.tar.xz" | sha256sum -c -; fi \
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
    --disable-werror \
    --build="$gnuArch" \
    --disable-install-doc \
    --enable-shared \
  && make -j "$(nproc)" \
  && make install \
  \
  && libDeps="$( \
    scanelf --needed --nobanner --format '%n#p' --recursive /usr/local \
      | tr ',' '\n' \
      | sort -u \
      | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
  )" \
  && runOnlyDeps=" \
    $libDeps \
    binutils \
    git \
    libc6-compat \
  " \
  && apk add --virtual .ruby-rundeps $baseDeps $runOnlyDeps \
  && apk del .ruby-builddeps \
  && cd / \
  && rm -r /usr/src/ruby

RUN SHELLCHECK_VERSION=v0.5.0 \
  && wget "https://storage.googleapis.com/shellcheck/shellcheck-$SHELLCHECK_VERSION.linux.x86_64.tar.xz" \
  && tar -xJf shellcheck-$SHELLCHECK_VERSION.linux.x86_64.tar.xz \
  && cp shellcheck-$SHELLCHECK_VERSION/shellcheck /usr/bin/

WORKDIR /byebug
