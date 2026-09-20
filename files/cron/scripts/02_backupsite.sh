#!/bin/sh

echo "[backup] create site backup" \
    > /proc/1/fd/1 \
    2> /proc/1/fd/2
tar czfv /var/backups/site/www_$(date +\%Y\%m\%d).tar.gz /var/www/html
echo "[backup] site backup done" \
    >/proc/1/fd/1 \
    2> /proc/1/fd/2