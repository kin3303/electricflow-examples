#!/usr/bin/env bash

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*)     machine=Linux;;
    Darwin*)    machine=Mac;;
    CYGWIN*)    machine=Cygwin;;
    MINGW*)     machine=MinGw;;
    *)          machine="UNKNOWN:${unameOut}"
esac
echo machine type is ${machine}

PARAMETERSFILE=input-model.json

ALL=1
APPLICATIONS=0
ENVIRONMENTS=0
PROCEDURES=0
PIPELINES=0
RELEASES=0
RESOURCES=0
SERVICES=0
TEST=0
WORKFLOWS=0
JSONONLY=0
INSTALL=0
SCHEMA=0
CONFIGURATION=0

# Parse command line
# Only a few options in place - see the help for details and update as needed.
while getopts ":AtrepwaslRSci:G:f:P:" opt; do
  case $opt in
    A)
        TEST=1
        RESOURCES=1
        ENVIRONMENTS=1
        PROCEDURES=1
        WORKFLOWS=1
        APPLICATIONS=1
        SERVICES=1
        PIPELINES=1
        RELEASES=1
        ;;
    c)
        CONFIGURATION=1
        ;;
    i)
        INSTALL=1
        INSTALLDIR=$OPTARG
        ;;
    t)
        TEST=1
        ;;
    r)
        RESOURCES=1
        ;;
    e)
        ENVIRONMENTS=1
        ;;
    p)
        PROCEDURES=1
        ;;
    w)
        WORKFLOWS=1
        ;;
    a)
        APPLICATIONS=1
        ;;
    s)
        SERVICES=1
        ;;
    l)
        PIPELINES=1
        ;;
    R)
        RELEASES=1
        ;;
    P)
        PROJECTNAME=$OPTARG
        echo "New project name is $PROJECTNAME"
        ;;
    f)
        PARAMETERSFILE=$OPTARG
        echo "parameters file is $PARAMETERSFILE"
        ;;
    G)
        GROUPID=$OPTARG
        echo "new groupId is $GROUPID"
        ;;
    S)
        SCHEMA=1
        ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      echo "Usage:" >&2
      echo "$0 [-A] [-i] [-c] [-t] [-r] [-e] [-p] [-w] [-a] [-s] [-p] [-R] [-P <PROJECT NAME>] [-G <GROUPID>] [-f <PARAMETERSFILE>] [-S] " >&2
      echo "  -A Do everything (trepwaspR)"
      echo "  -c Run configuration script"
      echo "  -i <PATH> install the software to named path.  Will always exit after this step."
      echo "  -t run unit tests on the model.  No objects are modified"
      echo "  -r create resources"
      echo "  -e create environments"
      echo "  -p create procedures"
      echo "  -w create workflows"
      echo "  -a create applications"
      echo "  -s create services"
      echo "  -p create pipelines"
      echo "  -R create releases"
      echo "  -P <PROJECTNAME> specify the name of the project"
      echo "  -G <GROUPID> specify the groupId in the format of 'com.ec.group.id'"
      echo "  -f <PARAMETERSFILE> use the named JSON file for input"
      echo "  -S print schema"
      exit 1
      ;;
  esac
done

# Find the root directory.
ROOT=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

if [ ${machine} = "Cygwin" ] ; then
    echo "You are using Cygwin. Adjusting $ROOT path"
    ROOT=`(cygpath $ROOT -w)`
    echo "root is $ROOT"
fi

if [ $INSTALL = "1" ] ; then

    echo "installing to $INSTALLDIR"
    if [ ! -d $INSTALLDIR/efmodels ] ; then
        echo "creating $INSTALLDIR/efmodels"
        mkdir $INSTALLDIR/efmodels
    fi
    cp *.groovy $INSTALLDIR/efmodels
    cp schema.json $INSTALLDIR/efmodels
    cp install.sh $INSTALLDIR/efmodel.sh
    chmod +x $INSTALLDIR/efmodel.sh
    exit 0
fi

if [ $SCHEMA = "1" ] ; then
    cat $ROOT/efmodels/schema.json
    exit 0
fi

# Run some essential tests to show the system works.  Good hygiene.
if [ $TEST = "1" ] ; then
    echo "######### TESTING #########"
    ectool evalDsl --dslFile "$ROOT/efmodels/test.groovy" --parametersFile $PARAMETERSFILE
fi

# Run some essential tests to show the system works.  Good hygiene.
if [ $CONFIGURATION = "1" ] ; then
    echo "######### CONFIGURATION #########"
    ectool evalDsl --dslFile $ROOT/efmodels/configuration.groovy --parametersFile $PARAMETERSFILE
fi

# Create the resources needed in this project.
if [ $RESOURCES = "1" ] ; then
    echo "######### CREATING RESOURCES #########"
    ectool evalDsl --dslFile $ROOT/efmodels/resources.groovy --parametersFile $PARAMETERSFILE
fi

# Create the environments needed in this project.
if [ $ENVIRONMENTS = "1" ] ; then
    echo "######### CREATING ENVIRONMENTS #########"
    ectool evalDsl --dslFile $ROOT/efmodels/environments.groovy --parametersFile $PARAMETERSFILE
fi

# all of the helper procedures are defined here.  This includes stubs.  We'll refer to procedures by name.
if [ $PROCEDURES = "1" ] ; then
    echo "######### CREATING PROCEDURES #########"
    ectool evalDsl --dslFile $ROOT/efmodels/procedures.groovy --parametersFile $PARAMETERSFILE
fi

# If you have workflows, define them here.  NOTE: Helper procedures should be already defined.
if [ $WORKFLOWS = "1" ] ; then
    echo "######### CREATING WORKFLOWS #########"
    ectool evalDsl --dslFile $ROOT/efmodels/workflows.groovy --parametersFile $PARAMETERSFILE
fi

# Your application model uses existing artifacts, procedures, and environments.
if [ $APPLICATIONS = "1" ] ; then
    echo "######### CREATING APPLICATIONS #########"
    ectool evalDsl --dslFile $ROOT/efmodels/applications.groovy --parametersFile $PARAMETERSFILE
fi

# Your services model uses existing procedures
if [ $SERVICES = "1" ] ; then
    echo "######### CREATING SERVICES #########"
    ectool evalDsl --dslFile $ROOT/efmodels/services.groovy --parametersFile $PARAMETERSFILE
fi

# The pipelines tie most things together.  One of the last steps.
if [ $PIPELINES = "1" ] ; then
    echo "######### CREATING PIPELINES #########"
    ectool evalDsl --dslFile $ROOT/efmodels/releases.groovy --parametersFile $PARAMETERSFILE
fi

# When we're ready, do the same for releases.
if [ $RELEASES = "1" ] ; then
   echo "######### RELEASES #########"
   ectool evalDsl --dslFile $ROOT/efmodels/releases.groovy --parametersFile $PARAMETERSFILE
fi
