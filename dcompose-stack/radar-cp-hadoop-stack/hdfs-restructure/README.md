## Scripts

This folder contains useful scripts to manage the extraction of data from HDFS in the RADAR-base Platform.

- `hdfs_restructure.sh`
  - This script uses the Restructure-HDFS-topic to extracts records from HDFS and converts them from AVRO to specified format
  - By default, the format is CSV, compression is set to gzip and deduplication is enabled.
  - To change configurations and for more info look at the [README here](https://github.com/RADAR-base/Restructure-HDFS-topic)

- `restracture_backup_hdfs.sh` for running the above script in a controlled manner with rotating logs
  - `logfile` is the log file where the script logs each operation
  - `storage_directory` is the directory where the extracted data will be stored
  - `lockfile` lock useful to check whether there is a previous instance still running

- A systemd timer for this script can be installed by running the `../install-systemd-wrappers.sh`. Or you can add a cron job like below.

To add a script to `CRON` as `root`, run on the command-line `sudo crontab -e -u root` and add your task at the end of the file. The syntax is
```shell
*     *     *     *     *  command to be executed
-     -     -     -     -
|     |     |     |     |
|     |     |     |     +----- day of week (0 - 6) (Sunday=0)
|     |     |     +------- month (1 - 12)
|     |     +--------- day of month (1 - 31)
|     +----------- hour (0 - 23)
+------------- min (0 - 59)
```

For example, `*/2 * * * * /absolute/path/to/script-name.sh` will execute `script-name.sh` every `2` minutes.
