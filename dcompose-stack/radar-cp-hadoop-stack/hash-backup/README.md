# HASH BACKUPS

This directory contains a unified solution to create backups for different paths (or directories) in the system. For a quickstart, the postgres path (configured in .env file) is already included by default.
-

- First configure all the parameters in the `backup.conf` file. Please note that the key and passphrase should be provided and be kept safe and backed up elsewhere.
- Then configure the remote destinations (if any) to send the backups to in the `dest.conf` file. Please look at the hashbackup documentation for more info on this. For a start FTP and Amazon s3 examples are included. Please note to leave the `dir` at any value since this will be eventually be replaced by the script based on the `ROOT_REMOTE_PATH` and `INPUTS` specified in the `backup.conf` file.
- Then run the initialization scripts
```shell
sudo bash initialize-hb.sh
```
- This should initialize the hashbackup output directories with the specified key and passphrase and apply any configurations.
- If the `SET_UP_TIMER` parameter in `backup.conf` is set to `true` then the above command automatically configures a `systemd timer` to run the backups (`./run-bakup.sh` script) daily at 3am. This can be changed in `/etc/systemd/system/radar-hashbackup.timer`.
- Alternatively, If you want to run this via CRON job just add the following to the crontab -
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


**Note**: If you want to run the backups once or manually, instead of using `systemd` or `CRON` you can just run the run backup script like -
```shell
sudo bash run-backup.sh
```
