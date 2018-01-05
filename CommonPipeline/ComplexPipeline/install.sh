#!/usr/bin/env bash

GROUPID=com.ec.complex.pipeline
PROJECTNAME=ComplexPipeline
MYJSONFILE=model.json

# Replace tokens with real names
sed -e "s/@@PROJECTNAMETOKEN@@/$PROJECTNAME/" input-model.json > $MYJSONFILE.project
sed -e "s/@@GROUPID@@/$GROUPID/" $MYJSONFILE.project > $MYJSONFILE

./install-config.sh -c -P $MYJSONFILE -N $PROJECTNAME -G $GROUPID
cd ..
./install.sh -A -P ComplexPipeline/$MYJSONFILE -N $PROJECTNAME -G $GROUPID
