#!/bin/bash

set -e

rsync -a /schema/original/commons /schema/original/specifications /schema/merged
rsync -a /schema/conf/ /schema/merged

# Compiling updated schemas
echo "Compiling schemas..." >&2
# Separate enums so that they can be referenced in later files
IFS=$'\n' read -r -a enums <<< $(find merged/commons -name "*.avsc" -exec grep -q '^  "type": "enum"' "{}" \; -print)
IFS=$'\n' read -r -a notenums <<< $(find merged/commons -name "*.avsc" -exec grep -qv '^  "type": "enum"' "{}" \; -print)
java -jar /usr/share/java/avro-tools.jar compile -string schema ${enums[@]} ${notenums[@]} java/src 2>/dev/null
find java/src -name "*.java" -print0 | xargs -0 javac -cp /usr/lib/*:java/classes -d java/classes -sourcepath java/src 
# Update the radar schemas so the tools find the new classes in classpath
jar uf /usr/lib/radar-schemas-commons-${RADAR_SCHEMAS_VERSION}.jar -C java/classes .

exec "$@"
