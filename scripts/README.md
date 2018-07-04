## Scripts

This folder contains useful scripts to manage the server where the RADAR-base Platform is running.

### `check_radar_network.sh`
**It checks if the machine is connected to internet. The script can be parametrised with the following**
-
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



### `hdfs-data-retention/hdfs_data_retention.sh`
**It is a script for deleting records from hdfs based on name of the topic and the date. All the records for the current topics older than the specified date are deleted from HDFS.**

  - `OUTPUT_DIR` - the directory where FS image file and extracted data will be stored. Default is `./tmp`
  - `date_time_to_remove_before` - All records for appropriate topics before this date will be removed from HDFS.
  - `HDFS_NAME_NODE` - The url of the hdfs namenode to download the FS image file and delete files.
  - `hdfs-data-retention/topics_to_remove.txt` - The file used by the above script to delete files from these topics. Please specify each topic on a new line.

Usage:
To just get the FS image file and process it and list the sum of file sizes of all the relevant files using apache pig, run the command like -
```shell
cd hdfs-data-retention
sudo bash hdfs_data_retention.sh
```
This will output the file sizes sum of the calculated paths like -
```
(SUM OF FILES SIZES TO BE DELETED IN MB = 46555)
```
and also store the finalised path meeting the conditions of topics and date in the `./tmp/final_paths/part_r_00000`

To also delete the files listed by the command above, just run -
```shell
cd hdfs-data-retention
sudo bash hdfs_data_retention.sh delete
```

Info:
By default the script is set up to run against docker containers in the RADAR-base stack.
The script will use the hdfs.image and hdfs.txt files from `./tmp` folder if present. To get a new FS image file from namenode, delete these files first and then run the script.

If you get JAVA_HOME not set error, please uncomment and specify the JAVA_HOME in the script.
