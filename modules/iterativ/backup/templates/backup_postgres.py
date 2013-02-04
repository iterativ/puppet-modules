#!/usr/bin/env python2
import os
import time
from subprocess import call, Popen, PIPE

def main():
    username = 'postgres'
    port = '5432'
    base_backup_dir = '/var/backups/postgres'
    date = time.strftime('%Y-%m-%dT%H-%M')
    current_backup_dir = base_backup_dir + "/pgbackup_" + date

    os.makedirs(current_backup_dir)

    # make fullbackup of the whole database with the pg_dumpall command
    call("pg_dumpall -U%s -p%s | gzip -c > %s/fullbackup_%s.sql.gz" % (username, port, current_backup_dir, date), shell=True)

    # get the names of all single databases
    all_db_query = 'SELECT datname FROM pg_database WHERE datallowconn = TRUE'
    get_db_names="psql -U%s -p%s -At -c '%s'" % (username, port, all_db_query)

    # making backup of every single database
    for base in Popen(get_db_names, shell=True, stdout=PIPE).stdout.readlines():
            base = base.decode().strip()
            filename = "%s/%s_%s.sql.gz" % (current_backup_dir, base, date)
            call("pg_dump -C -U%s -p%s %s | gzip -c > %s" % (username, port, base, filename), shell=True)

if __name__ == "__main__":
    main()

