## Scripts

This folder contains useful scripts to manage the server where the RADAR-base Platform is running.

- `check_radar_network.sh` checks if the machine is connected to internet. The script can be parametrised with
  - `nic` is the internet gateway
  - `lockfile` lock usefull to check whether there is a previous instance still running
  - `logfile` is the log file where the script logs each operation
  - `url` is the web site used to check the connectivity

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

Before deploying the task, make sure that all paths used by the script are absolute. Replace the relative path to `util.sh` with the absolute one.
