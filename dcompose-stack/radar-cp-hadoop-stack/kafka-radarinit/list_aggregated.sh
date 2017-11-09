#/bin/bash

SAVEIFS=$IFS
# Change IFS to new line.
raw_str=$(radar-schemas-tools list -q --raw merged)
all_str=$(radar-schemas-tools list -q merged)
IFS=$'\n'
raw=($raw_str)
all=($all_str)
# Restore IFS
IFS=$SAVEIFS

aggregated=()
for i in "${all[@]}"; do
   skip=
   for j in "${raw[@]}"; do
       [[ $i == $j ]] && { skip=1; break; }
   done
   [[ -n $skip ]] || aggregated+=("$i")
done
IFS=','
echo "${aggregated[*]}"