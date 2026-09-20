#!/bin/sh

env >> /etc/environment

# execute CMD
echo "Start cron" >/proc/1/fd/1 2>/proc/1/fd/2
echo "$@"
exec "$@"