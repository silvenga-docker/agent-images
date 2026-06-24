#!/bin/sh
set -e

CACERTS_DIR=/var/lib/java-cacerts
CACERTS_FILE=${CACERTS_DIR}/cacerts
JAVA_CLASS=/usr/local/bin/gen-cacerts.class

mkdir -p "${CACERTS_DIR}"
rm -f "${CACERTS_FILE}"

java -cp /usr/local/bin gen_cacerts

chmod 0644 "${CACERTS_FILE}"