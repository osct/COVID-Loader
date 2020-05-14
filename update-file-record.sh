#!/bin/bash

 

out() {
#  TS=$(date +"%Y-%m-%d %H:%M:%S")
#  printf "[%s %s]: %s\n" $TS "$*" >&1
  printf "%s\n" "$*" >&1
}

 

err() {
#  TS=$(date +"%Y-%m-%d %H:%M:%S")
#  printf "[%s %s]: %s\n" $TS "$*" >&2
    printf "%s\n" "$*" >&2
}

 

show_usage() {
  SCRIPT=$(basename $0)
  out "Usage: $SCRIPT <record_id> <file1_to_update> <file2_to_update> .... <filen_to_update>"
  err "At least one file is mandatory"
  exit 1
}


if [ -z ${TOKEN+x} ]; then
  err "Access token must be provided in the variable TOKEN"
  exit
fi

if [ -z ${URL+x} ]; then
  err "URL end-point must be provided in the variable URL"
  exit
fi

if [ $# -lt 2 ]; then
  show_usage
  exit 1
fi

RECORD=$1
shift

NEW_DEP_URL=$(curl -k -s -X POST "${URL}/api/deposit/depositions/${RECORD}/actions/newversion?access_token=${TOKEN}" | jq ".links.latest_draft" | sed 's/"//g')

if [ ${NEW_DEP_URL:0:4} != "http" ]; then
  err "Cannot generate the new deposit"
  exit 2
fi

FILE_OLD=$(curl -k -s "${NEW_DEP_URL}?access_token=${TOKEN}" | jq ".files[].id"  | sed 's/"//g')
for FILE_ID in $FILE_OLD; do
  FILE_OP=$(curl -k -s --write-out "%{http_code}\n" -X DELETE "${NEW_DEP_URL}/files/${FILE_ID}?access_token=${TOKEN}")
  if [ $FILE_OP != "204" ]; then
    err "Impossible to remove the old file from the new deposit"
    exit 2
  fi
done

for FILEPATH in $@ ; do
  FILE_OP=$(curl -k -s "${NEW_DEP_URL}/files?access_token=${TOKEN}" -F "name=${FILEPATH/*\//}" -F "file=@$FILEPATH"  | jq ".id"  | sed 's/"//g')

  if [ -z $FILE_OP ]; then
    err "Impossible to add the new file in the new deposit"
    exit 2
  fi
done


METADATA=$(curl -k -s "${NEW_DEP_URL}?access_token=${TOKEN}" | jq .metadata |jq ".publication_date=\"$(date +%Y-%m-%d -d "1 day ago")\" | del(.preserve_doi)")


FILE_OP=$(curl -k -s -H "Content-Type: application/json" --data "{\"metadata\": $METADATA}" -X PUT "${NEW_DEP_URL}?access_token=${TOKEN}")

PUB=$(curl -k -s -X POST "${NEW_DEP_URL}/actions/publish?access_token=${TOKEN}" | jq ".doi"  | sed 's/"//g')


if [ -z $PUB ]; then
  err "Impossible to publish the new deposit"
  exit 3
fi

out "DOI: ${PUB}"
