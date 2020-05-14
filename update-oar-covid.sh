#!/bin/bash
DOCDIR=covid19_infn_docdir
DOCUMENTS=covid19_infn_oar

[ ! -x loader.sh ] &&\
  echo "Downloaded file not found" &&\
  exit 1
  ./loader.sh $(date +%Y-%m-%d -d "1 day ago")

tar xfz $DOCDIR/allFiles.tar.gz -C $DOCDIR
rm  -f $DOCDIR/allFiles.tar.gz

tar cfz $DOCDIR/covid19-root.tar.gz -C $DOCDIR rootFiles
rm -rf $DOCDIR/rootFiles

# get documents from web site
while read docrecord; do
  [ "$docrecord" = "" -o\
    $(echo "$docrecord" | grep "^#" | wc -l) -ne 0 ] &&\
    continue
  DOCREC=$(echo $docrecord | awk -F':' '{ print $1 }') &&\
  DOCFILE=$(echo $docrecord | awk -F':' '{ print $2 }' | sed s/%d/$TODAY/) &&\
  FILES=""
  for i in $DOCFILE ; do FILES="$FILES $DOCDIR/$i" ; done &&\
  ./update-file-record.sh $DOCREC $FILES
done < $DOCUMENTS

rm $DOCDIR/*
