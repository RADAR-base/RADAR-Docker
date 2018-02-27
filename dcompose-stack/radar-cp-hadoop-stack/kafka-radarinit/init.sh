#!/bin/bash

set -e

rsync -a /schema/original/commons /schema/original/specifications /schema/merged
rsync -a /schema/conf/ /schema/merged

# Compiling updated schemas
echo "Compiling schemas..." >&2

# Regex for schemas with a dependency that is a class
# e.g., a literal class starting with a capital, or
# a namespace with internal periods.
DEPENDENT_REGEX='"(items|type)": (\[\s*"null",\s*)?"([A-Z]|[^".]*\.)'
# Separate enums so that they can be referenced in later files
read -r -a notdependent <<< $(find merged/commons -name "*.avsc" -exec grep -Eqv "$DEPENDENT_REGEX" "{}" \; -print | tr '\n' ' ')
read -r -a dependent <<< $(find merged/commons -name "*.avsc" -exec grep -Eq "$DEPENDENT_REGEX" \; -print | tr '\n' ' ')
java -jar /usr/share/java/avro-tools.jar compile -string schema ${notdependent[@]} ${dependent[@]} java/src 2>/dev/null
find java/src -name "*.java" -print0 | xargs -0 javac -cp /usr/lib/*:java/classes -d java/classes -sourcepath java/src 
# Update the radar schemas so the tools find the new classes in classpath
jar uf /usr/lib/radar-schemas-commons-${RADAR_SCHEMAS_VERSION}.jar -C java/classes .

exec "$@"
