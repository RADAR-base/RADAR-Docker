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

find merged/commons -name "*.avsc" -print | sort > merged/file_list
find merged/commons -name "*.avsc" -exec grep -Eq "$DEPENDENT_REGEX" "{}" \; -print | sort > merged/file_list_dependent
comm -23 merged/file_list merged/file_list_dependent > merged/file_list_independent

# Separate enums so that they can be referenced in later files
read -r -a independent <<< $(tr '\n' ' ' < merged/file_list_independent)
read -r -a dependent <<< $(tr '\n' ' ' < merged/file_list_dependent)

printf "===> Independent schemas:\n$(echo ${independent[@]})\n"
printf "===> Dependent schemas:\n$(echo ${dependent[@]})\n"

java -jar /usr/share/java/avro-tools.jar compile -string schema ${independent[@]} ${dependent[@]} java/src 2>/dev/null
find java/src -name "*.java" -print0 | xargs -0 javac -cp /usr/lib/*:java/classes -d java/classes -sourcepath java/src 
# Update the radar schemas so the tools find the new classes in classpath
jar uf /usr/lib/radar-schemas-commons-${RADAR_SCHEMAS_VERSION}.jar -C java/classes .

exec "$@"
