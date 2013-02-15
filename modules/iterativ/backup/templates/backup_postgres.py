#!/usr/bin/env python2
import os
from subprocess import call, Popen, PIPE
import shutil
import tarfile


class PostgresBackup(object):
    def __init__(self):
        self.username = 'postgres'
        self.port = '5432'
        self.base_backup_dir = '/var/backups/postgres'
        self.current_backup_file = self.base_backup_dir + '/pgbackup.tar.bz2'
        self.backup_dir_name = 'pgbackup'
        self.current_backup_dir = self.base_backup_dir + '/' + self.backup_dir_name

    def _local_cleanup(self):
        if os.path.exists(self.current_backup_dir):
            shutil.rmtree(self.current_backup_dir)
        if os.path.exists(self.current_backup_file):
            os.remove(self.current_backup_file)
        os.makedirs(self.current_backup_dir)

    def _full_db_backup(self):
        call("pg_dumpall -U{username} -p{port} > {current_backup_dir}/fullbackup.sql".format(
            username=self.username,
            port=self.port,
            current_backup_dir=self.current_backup_dir), shell=True)

    def _single_db_backup(self):
        all_db_query = 'SELECT datname FROM pg_database WHERE datallowconn = TRUE'
        command = "psql -U{username} -p{port} -At -c '{query}'".format(
            username=self.username,
            port=self.port,
            query=all_db_query
        )

        # making backup of every single database
        for base in Popen(command, shell=True, stdout=PIPE).stdout.readlines():
            base = base.decode().strip()
            file_path = "{backup_dir}/{db_name}.sql".format(backup_dir=self.current_backup_dir, db_name=base)
            call("pg_dump -C -U{username} -p{port} {db_name} > {file_path}".format(
                username=self.username,
                port=self.port,
                db_name=base,
                file_path=file_path), shell=True)

    def _compress_file(self):
        os.chdir(self.base_backup_dir)
        tar = tarfile.open(self.current_backup_file, "w:bz2")
        tar.add(self.backup_dir_name)
        tar.close()

    def go(self):
        self._local_cleanup()
        self._full_db_backup()
        self._single_db_backup()
        self._compress_file()


if __name__ == "__main__":
    pg_backup = PostgresBackup()
    pg_backup.go()
