#!/bin/sh

USER_UID=$(stat -c %u /byebug/Gemfile)
USER_GID=$(stat -c %g /byebug/Gemfile)

export USER_UID
export USER_GID

usermod -u "$USER_UID" byebug 2> /dev/null
groupmod -g "$USER_GID" byebug 2> /dev/null
usermod -g "$USER_GID" byebug 2> /dev/null

/usr/bin/sudo -EH -u byebug "$@"
