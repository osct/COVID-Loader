#!/bin/bash
#
# loader.sh - Load data related to web site https://covid19.infn.it
#
DOCDIR=covid19_infn_docdir
DOCUMENTS=covid19_infn_documents

# reset documents dir
[ -d $DOCDIR ] && rm -rf $DOCDIR
mkdir -p $DOCDIR

# check the document file
[ ! -f $DOCUMENTS ] &&\
  echo "Document file '"$DOCUMENTS"' does not exists" &&\
  exit 1

# check input argument (date) or use current date
[ -z ${1} ] &&\
  TODAY=$(date +%Y-%m-%d) ||\
  TODAY=$1

# get documents from web site
while read docrecord; do
  [ "$docrecord" = "" -o\
    $(echo "$docrecord" | grep "^#" | wc -l) -ne 0 ] &&\
    continue
  DOCDESC=$(echo $docrecord | awk -F',' '{ print $1 }') &&\
  DOCURL=$(echo $docrecord | awk -F',' '{ print $2 }' | sed s/%d/$TODAY/) &&\
  DOCNAME=$(basename "$DOCURL") &&\
  LOADCMD="curl --fail -L $DOCURL -o $DOCDIR/$DOCNAME" &&\
  printf "Loading $DOCDESC ... " &&\
  $LOADCMD 2>/dev/null &&\
  RES=$? &&\
  echo "ok ($RES)" ||\
  echo "failed ($?)"
done < $DOCUMENTS

