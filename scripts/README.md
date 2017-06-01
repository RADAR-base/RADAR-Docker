## Scripts

This folder contains useful scripts to manage the server where the RADAR-CNS Platform is running.

- `check-radar-network.sh` checks if the machine is connected to internet. The script can be parametrised with
  - `nic` is the internet gateway
  - `lockfile` lock usefull to check whether there is a previous instance still running
  - `logfile` is the log file where the script logs each operation
  - `url` is the web site used to check the connectivity

- `restracture-backup-hdfs.sh`
  - `logfile` is the log file where the script logs each operation
  - `working_directory` is the directory where the `hdfs_restructure.sh` script is located.
  - `storage_directory` is the directory where the extracted data will be stored
  - `lockfile` lock usefull to check whether there is a previous instance still running

To add a script to `CRON` as `root`, run on the command-line `sudo crontab -e -u root` and add  `*/2 * * * * /absolute/path/to/script-name.sh` at the end of the file. In this way, the script will be fired every `2` minutes. Before deploying the task, check that all paths used by the script are absolute.
