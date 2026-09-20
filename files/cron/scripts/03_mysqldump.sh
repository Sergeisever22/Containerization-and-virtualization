#!/bin/sh

echo "[backup] create mysql dump of ${MARIADB_DATABASE} database" \
    > /proc/1/fd/1
mysqldump -u ${MARIADB_USER} --password=${MARIADB_PASSWORD} -v -h mariadb ${MARIADB_DATABASE} \
    | gzip -c > /var/backups/mysql/${MARIADB_DATABASE}_$(date +\%F_\%T).sql.gz 2> /proc/1/fd/1
echo "[backup] sql dump created" \
    > /proc/1/fd/1