#!/usr/bin/env bash

mkdir -p inotify
#nohup ish -c "inotifywait -m . 2>&1 | awk '{ print strftime(\"[%Y-%m-%d %H:%M:%S]\"), \$0 }'" > inotify/inotify.log 2>&1 &
nohup script -q -c "inotifywait -m . 2>&1 | awk '{ print strftime(\"[%Y-%m-%d %H:%M:%S]\"), \$0 }'" /dev/null > inotify/inotify.log 2>&1 &
