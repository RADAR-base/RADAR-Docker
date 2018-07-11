## Scripts

This folder contains useful scripts to manage the server where the RADAR-base Platform is running.

### `check_radar_network.sh`
**It checks if the machine is connected to internet. The script can be parametrised with the following**

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
  - `hdfs-data-retention/topics_to_remove.txt` - The default file used by the above script to delete files from these topics. Please specify each topic on a new line.

Usage:
To just get the FS image file and process it and list the sum of file sizes of all the relevant files using apache pig, run the command like -
```shell
cd hdfs-data-retention
sudo bash hdfs_data_retention.sh --date "2018-03-15 12:00"
```
This will output the file sizes sum of the calculated paths like -
```
(SUM OF FILES SIZES TO BE DELETED IN MB = 46555)
```
and also store the finalised path meeting the conditions of topics and date in the `./tmp/final_paths/part_r_00000`

To also delete the files and other options see below -
```
Usage: ./hdfs_data_retention.sh --date <date and time to delete before> [Options...]
Options: ** means required

  -d|--delete: enable delete for the data. If not specified, the size of selected files is displayed.
  -st|--skip-trash: Enables skipTrash option for <hdfs dfs -rm>. To be used with -d|--delete option.
* -u|--url: The HDFS namenode Url to connect to. Default is hdfs://hdfs-namenode:8020
* -tf|--topics-file: The path of the file containing the newline-separated list of topics to remove the files from. Default is ./topics_to_remove.txt
** -dt|--date: All the files modified before this date time will be selected. Format is (yyyy-MM-dd HH:mm)
```
Recommended use of the script for large filesystems is via a Cron job or a Screen session as it may take some time to delete all the files.

Info:
By default the script is set up to run against docker containers in the RADAR-base stack.
The script will use the hdfs.image and hdfs.txt files from `./tmp` folder if delete is specified and the files are not older than a day.

If you get JAVA_HOME not set error, please uncomment and specify the JAVA_HOME in the script.
