# HASH BACKUPS

This directory contains a unified solution to create backups for different paths (or directories) in the system. For a quickstart, the postgres path (configured in .env file) is already included by default.
-

- First configure all the parameters in the `backup.conf` file. Please note that the key and passphrase should be provided and be kept safe and backed up elsewhere.
- The passphrase will be taken from the environment variable HBPASS whenever access to the backup is requested. A passphrase secures backup data: - for users in hosted or managed environments, like a VPS - when the backup directory is on USB thumb drives - when the backup directory is on mounted storage like Google Drive, Amazon Cloud Drive, Dropbox, etc. additional details here - [HashBackup Security](http://www.hashbackup.com/technical/security)
- Then configure the remote destinations (if any) to send the backups to in the `dest.conf` file. Please look at the hashbackup documentation for more info on this. For a start FTP and Amazon s3 examples are included. Please note to leave the `dir` at any value since this will be eventually be replaced by the script based on the `ROOT_REMOTE_PATH` and `INPUTS` specified in the `backup.conf` file.
- Then run the initialization scripts
```shell
sudo bash initialize-hb.sh
```
- This should initialize the hashbackup output directories with the specified key and passphrase and apply any configurations.
- If the `SET_UP_TIMER` parameter in `backup.conf` is set to `true` then the above command automatically configures a `systemd timer` to run the backups (`./run-bakup.sh` script) daily at 3am. This can be changed in `/etc/systemd/system/radar-hashbackup.timer`.
- systemd timer is recommended but you may alternatively, run this via CRON job just add the following to the crontab -
```
00 03 * * * root sudo bash /<YOUR RADAR-Docker path>/dcompose-stack/radar-cp-hadoop-stack/hash-backup/run-backup.sh
```

If the `systemd` timer is set to run the backups, then the backup should be controlled via `systemctl`.
```shell
# query the latest status and logs of the backup service
sudo systemctl status radar-hashbackup

# Stop backup timer
sudo systemctl stop radar-hashbackup.timer

# Restart backup timer
sudo systemctl reload radar-hashbackup.timer

# Start backup timer
sudo systemctl start radar-hashbackup.timer

# Full radar-hashbackup system logs
sudo journalctl -u radar-hashbackup
```
The CRON job should preferably not be used if `systemd` is used. To remove `systemctl` integration, run
```
sudo systemctl disable radar-hashbackup
```


**Notes**:
If you want to run the backups once or manually, instead of using `systemd` or `CRON` you can just run the run backup script like -
```shell
sudo bash run-backup.sh
```

Also remember to upgrade hash backup frequently (~ every 3 months) since it is stated in documentation that - `The compatibility goal is that backups created less than a year ago should be accessible with the latest version.`

Currently, the hashbackups are configured to use input paths but for systems like databases, you should prefer first creating dump of the database on a filepath and then using that path in the hashbackup configuration.
This can be easily done using a cron job for example -
This is for creating a dump of the postgres db running inside a docker container on a directory on the host named `/localpostgresdump` every night at 12 -

```
00 00 * * * docker exec <container_name> pg_dumpall > /localpostgresdump/backup
```

You can then add the path `/localpostgresdump` in the `backup.conf` file in `INPUTS` which will create a backup of SQL dumps.


## Important INFO
Quoting the Hashbackup Docs from the download page -
```
Beta versions of HashBackup expire quarterly on the 15th of January, April, July, and October. Use hb upgrade to get the latest version and extend the expiration date.
IMPORTANT: You can always access your backup data after the expiration date: everything continues to work except the backup command.
```

This means you will need to upgrade Hashbackup regularly. You can easily set up a CRON job to accomplish this. The following example shows how to upgrade every week at 1 AM on a Sunday.
```
0 1 * * 0 root hb upgrade
```
