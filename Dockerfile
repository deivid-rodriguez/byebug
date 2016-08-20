FROM ubuntu:16.04
MAINTAINER deivid.rodriguez@riseup.net

RUN useradd -ms /bin/bash app

USER root
RUN apt-get update && apt-get install -y \
  autoconf \
  automake \
  bison \
  bzip2 \
  curl \
  gawk \
  g++ \
  gcc \
  git \
  indent \
  libc6-dev \
  libffi-dev \
  libgdbm-dev \
  libgmp-dev \
  libncurses5-dev \
  libreadline6-dev \
  libedit-dev \
  libsqlite3-dev \
  libssl-dev \
  libyaml-dev \
  libtool \
  make \
  patch \
  pkg-config \
  shellcheck \
  sqlite3 \
  zlib1g-dev

RUN mkdir /app
WORKDIR /app
ADD . ./
RUN chown -R app:app /app

USER app

RUN git config --local user.email 'docker@example.org'
RUN git config --local user.name 'Docker CI'

RUN gpg --keyserver hkp://keys.gnupg.net \
        --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3

RUN /bin/bash -l -c "curl -L https://get.rvm.io | bash -s stable"
RUN /bin/bash -l -c "source /home/app/.rvm/scripts/rvm"
RUN /bin/bash -l -c "rvm install 2.3.1 --configure --enable-libedit --autolibs=read-fail"
RUN /bin/bash -l -c "rvm alias create ruby-with-libedit 2.3.1"
RUN /bin/bash -l -c "rvm use ruby-with-libedit && gem install bundler && bundle install"
RUN /bin/bash -l -c "bundle exec overcommit --sign"
