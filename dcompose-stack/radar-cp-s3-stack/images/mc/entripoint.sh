#!/bin/bash


# Replace env vars in JavaScript files
echo "Waiting for minio service to start..."

tries=10
timeout=1
max_timeout=32
while true; do
  if curl -Ifs "${MINIO_ENDPOINT}" > /dev/null; then
    break;
  fi
  tries=$((tries - 1))
  if [ $tries = 0 ]; then
    echo "FAILED TO REACH MINIO. CANNOT REGISTER A BUCKET"
    exit 1
  fi
  echo "Failed to reach minio. Retrying in ${timeout} seconds."
  sleep $timeout
  if [ $timeout -lt $max_timeout ]; then
    timeout=$((timeout * 2))
  fi
done

echo "Connected! to minio"

echo "Configuring bucket..."
mc config host add  radarbase-minio ${MINIO_ENDPOINT} ${MINIO_ACCESS_KEY} ${MINIO_SECRET_KEY}
mc mb -p myminio/${MINIO_INTERMEDIATE_BUCKET_NAME}
#mc policy download myminio/${MINIO_INTERMEDIATE_BUCKET_NAME}
#mc policy upload myminio/${MINIO_INTERMEDIATE_BUCKET_NAME}

