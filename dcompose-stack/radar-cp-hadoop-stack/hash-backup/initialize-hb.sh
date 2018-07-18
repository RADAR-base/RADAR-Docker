#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
. "./backup.conf"
. "../lib/util.sh" > /dev/null

IFS=',' read -r -a inputs <<< "$INPUTS"

# install hash backup if it does not exist
if hash hb 2>/dev/null
then
     echo "Hash backup detected.  Proceeding..."
else
     echo "Installing Hash Backup..."
     mkdir tmp
     wget -q -P tmp http://www.hashbackup.com/download/hb-"${HB_VERSION}"-linux-64bit.tar.gz
     tar -xzf tmp/hb-*.tar.gz -C tmp
     sudo-linux cp tmp/hb-"${HB_VERSION}"/hb /usr/local/bin
     rm -r tmp
     echo "Hash Backup installed...."
fi

# initialize a backup directory for each input path and set up remote destinations
for element in "${inputs[@]}"
do
     if [[ ! -d $element ]]
     then
          echo "The input path ${element} is not a directory."
          exit 1
     fi

     echo "Initializing backup for input: ${element}"
     backupSubpath=$(basename "${element}")
     finalPath="${OUTPUT}/${backupSubpath}"

     # Only init if the directory does not exist
     if [[ ! -d $finalPath ]]
     then
          export HBPASS=${PASSPHRASE}
          hb init -c ${finalPath} -k "${KEY}" -p "env"
          if [ ! -z ${LOCAL_SIZE} ]
          then
               hb config -c ${finalPath} cache-size-limit ${LOCAL_SIZE}
          fi
          if [ ! -z ${ARC_SIZE} ]
          then
               hb config -c ${finalPath} arc-size-limit ${ARC_SIZE}
          fi
          cp dest.conf "${finalPath}"/dest.conf
          # Set up remote directory according to input path and remote root dir
          sed -i -e "s~dir.*~dir ${ROOT_REMOTE_PATH}/${backupSubpath}/~g" "${finalPath}"/dest.conf
     else
          echo "Output Directory ${finalPath} already exists, Skipping initializing it..."
     fi
done

if [[ ${SET_UP_TIMER} -eq true ]]
then
     check_command_exists systemctl
     copy_template_if_absent /etc/systemd/system/radar-hashbackup.service systemd/radar-hashbackup.service.template
     copy_template_if_absent /etc/systemd/system/radar-hashbackup.timer systemd/radar-hashbackup.timer.template

     DIR="$( pwd )"
     sudo chmod +x $DIR/run-backup.sh
     inline_variable 'WorkingDirectory=' "$DIR" /etc/systemd/system/radar-hashbackup.service
     inline_variable 'ExecStart=' "$DIR/run-backup.sh" /etc/systemd/system/radar-hashbackup.service

     sudo systemctl daemon-reload
     sudo systemctl enable radar-hashbackup.timer
     sudo systemctl start radar-hashbackup.timer
fi
