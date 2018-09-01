#!/bin/sh -x

USER_UID=$(stat -c %u /byebug/Gemfile)
USER_GID=$(stat -c %g /byebug/Gemfile)

usermod -u "$USER_UID" docker
groupmod -g "$USER_GID" docker
usermod -g "$USER_GID" docker

/usr/bin/sudo -EH -u docker "$@"
