#!/bin/bash
cd "$( dirname "${BASH_SOURCE[0]}" )"
. "./backup.conf"

# lock file
lockfile=.LOCKFILE

if [ ! -f $lockfile ]; then
  echo "Creating lock ..."
  touch $lockfile
  IFS=',' read -r -a inputs <<< "$INPUTS"

  for element in "${inputs[@]}"
  do
     if [[ ! -d $element ]]
     then
          echo "The input path ${element} is not a directory."
          exit 1
     fi

     echo "Running backup for input: ${element}"
     backupSubpath=$(basename "${element}")
     finalPath="${OUTPUT}/${backupSubpath}"
     hb log backup -c ${finalPath} ${element} ${DEDUPLICATE_MEMORY} -X
     hb log retain -c ${finalPath} ${RETAIN} ${DELETED_RETAIN} -v
     hb log selftest -c ${finalPath} -v4 --inc 1d/120d --sample 4
  done
  echo "Removing lock ..."
  rm $lockfile
else
  echo "Another instance is already running ... "
fi
echo "### DONE ###"
