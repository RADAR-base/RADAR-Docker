## Scripts

This folder contains useful scripts to manage the server where the RADAR-CNS Platform is running.

- `check-radar-network.sh` checks if the machine is connected to internet. The check is done "curling" `http://www.kcl.ac.uk`. The script can be parametrised with
  - `nic` is the internet gateway
  - `lockfile` lock usefull to check whether there is a previous instance still running
  - `logfile` is the log file where the script logs each operation

To add a script to `CRON` as `root`, run on the command-line `sudo crontab -e -u root` and add  `*/2 * * * * /path/to/script-name.sh` at the end of the file. In this way, the script will be fired every `2` minutes. Before deploying the task, check that all paths used by the scritp are absolute.
