#!/bin/bash

## Backup Script Nick Leffler 20190326 ##

servername=$(hostname --fqdn)
date22=$(date +'%Y%m%d_%H%M')
bdir="/opt/backup"
dir="${bdir}/${date22}"
sqlDir="${dir}/mysql"
destServ="macroplexa.nicks.tv"
desDir="/data/backup" # with no trailing /
destUser="backupdude"

# make sure to add the ssh-keys from the source server on the dest #
# remember you need at least the compressed size as free space #

mkdir -p "${dir}" || exit

sqlBackup () {
 mkdir -p "${sqlDir}" || exit
 databases=`mysql -e "SHOW DATABASES;" | grep -Ev "(Database|information_schema|performance_schema)"`
 for db in $databases; do
  mysqldump --force --opt --databases $db > "${sqlDir}/$db.sql"
 done
 tar -Jcf "${dir}/${date22}_mysql.tar.xz" "${sqlDir}" > /dev/null 2>&1
 sleep 4
 rm -rf "${sqlDir}"
}

# SQL Backup
sqlBackup

# nginx backup
tar -Jcf "${dir}/${date22}_nginx.tar.xz" "/etc/nginx/" > /dev/null 2>&1

# backup postfix config
#tar -Jcf "${dir}/${date22}_postfix.tar.xz" "/etc/postfix/" > /dev/null 2>&1

# backup dovcecot config
#tar -Jcf "${dir}/${date22}_dovecot.tar.xz" "/etc/dovecot/" > /dev/null 2>&1

# backup certbot config
#tar -Jcf "${dir}/${date22}_certbot.tar.xz" "/etc/certbot/" > /dev/null 2>&1

# WWW data backup
tar --exclude='old' -Jcf "${dir}/${date22}_www.tar.xz" "/usr/share/nginx/html/" > /dev/null 2>&1

# Copy to backup server
rsync -v -a -e "ssh -p 22" "${bdir}"/ "${destUser}@${destServ}:${desDir}/${servername}/"

# delete older than a week # actually not in use
#find "${bdir}/" -type f -delete
#find "${bdir}/" -type d -empty -delete

# delete after backup completed
rm -rfv "${bdir}/"*
