# POSTGRES Backup Scripts

**Note These Scripts Have been Deprecated. Please use the unified backup solution provided in `hash-backup` folder. This folder will be removed in the future.**

The `scripts` directory contains a script for running roatated backups of a running postgres instance. In this case these scripts are mounted to the postgres container (using bind mounts)  and then run to create backups. These scripts are taken from the [postgres wiki](https://wiki.postgresql.org/wiki/Automated_Backup_on_Linux)

The backups can be configured to create daily, weekly and monthly backups by configuring the `pg_backup.config` configuration file. Please note that if you change the `BACKUP_DIR` in the config file then make sure to change the bind mount in the postgres container in docker-compose.yml file as well.
Further configuration information is contained in the `pg_backup.config` file.

This scripts needs to be run periodically which is based on your preference and can be done through cron job or a systemd timer.
The backups are then stored in `postgres-backup/backups` directory

Example cron job for daily running this script on postgres container at midnight is -
```
00 00 * * * docker exec radarcphadoopstack_managementportal-postgresql_1 ./backup-scripts/pg_backup_rotated.sh >> ~/pg_backup.log 2>&1
```

This also logs the output to a file.
