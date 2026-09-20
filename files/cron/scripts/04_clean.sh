#!/bin/sh

echo "[backup] remove old backups" \
    > /proc/1/fd/1 \
    2> /proc/1/fd/2
find /var/backups/mysql -type f -mtime +30 -delete \
    > /proc/1/fd/1 \
    2> /proc/1/fd/2
find /var/backups/site -type f -mtime +30 -delete \
    > /proc/1/fd/1 \
    2> /proc/1/fd/2
echo "[backup] done" \
    > /proc/1/fd/1 \
    2> /proc/1/fd/2