#!/usr/bin/env bash

# Filename: pull.sh
# 
# Copyright 2019 Calvin Ardi
# 
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
# 
#     http://www.apache.org/licenses/LICENSE-2.0
# 
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# easiest way automate this is to install this in your crontab:
#
# run five minutes after midnight, every day
# 5 0 * * * /path/to/aws-spot-price-history/pull.sh >> /path/to/aws-spot-price-history/log.txt

# to be crontab compatible
cd $(dirname $0)

export JAVA_HOME=/usr/lib/jvm/java/jre

# if you don't have the ec2-api-tools already, run the following in
# the directory this script is in:
#
#   curl -O http://s3.amazonaws.com/ec2-downloads/ec2-api-tools.zip
#   unzip -q ec2-api-tools.zip
#   ln -s ec2-api-tools-*/ ec2-api-tools
#
export EC2_HOME=`pwd`/ec2-api-tools

# replace keys with your own, or drop them in the following files
export AWS_ACCESS_KEY=`cat aws_access.private`
export AWS_SECRET_KEY=`cat aws_secret.private`

# where do you want the data?
export DATA_DIR=data

# to get the available regions:
#
#   ec2-describe-regions | awk {'print $2'} | tr '\n' ' '
#
# `ec2-describe-regions` does take some time, so it's easier to
# update the variable when it has changed
REGIONS=( eu-north-1 ap-south-1 eu-west-3 eu-west-2 eu-west-1 ap-northeast-2
    ap-northeast-1 sa-east-1 ca-central-1 ap-southeast-1 ap-southeast-2
    eu-central-1 us-east-1 us-east-2 us-west-1 us-west-2 )

TS="date -Iseconds"

# check if data directory exists
if [ -d "$DATA_DIR" ];
then
    # $DATA_DIR exists and is a directory (or a symlink to one), cd into it
    cd $DATA_DIR
elif [ ! -e "$DATA_DIR" ];
then
    # nothing named $DATA_DIR exists, mkdir then cd into it
    mkdir $DATA_DIR
    cd $DATA_DIR
else
    # something that isn't a directory named "$DATA_DIR" exists, exit
    echo "`$TS` $DATA_DIR exists and isn't a directory, exiting..."
    exit 1
fi

# we could parallelize this loop, but it's best to naturally throttle
# so we don't unduly burden their servers
for region in "${REGIONS[@]}"
do
    echo "`$TS` $region starting"

    # do we already have data?
    DATA_NEWEST="data.$region.newest"
    if [ -e $DATA_NEWEST ];
    then
        # grab the most recent entry timestamp (e.g., 2017-02-02T11:45:34-0800)
        NEWEST_TS=`head -20 $DATA_NEWEST | awk -F'\t' '{print $3}' | sort -r | head -1`
        echo "`$TS` $region existing data found: most recent timestamp is $NEWEST_TS"
    else
        unset NEWEST_TS
        echo "`$TS` $region no existing data found, starting from the beginning (otherwise symlink 'data.$region.newest' to the most recent file)"
        echo "`$TS` $region note: the initial data pull can take a while (~1 hour)"
    fi

    # we can only grab the last 90 days of data: if the most recent timestamp is
    # more than 90 days ago then we're essentially starting from scratch.
    FN_TEMP=data.$region.`date -Iseconds`.temp
    echo "`$TS` $region starting data refresh"
    if [ ! -z "$NEWEST_TS" ];
    then
        # only get the diff, but there will be some overlap regardless
        $EC2_HOME/bin/ec2-describe-spot-price-history \
            --region $region \
            --start-time $NEWEST_TS \
            > $FN_TEMP
    else
        $EC2_HOME/bin/ec2-describe-spot-price-history \
            --region $region \
            > $FN_TEMP
    fi

    # if the data refresh is finished, then move the files around and update
    # symlinks.
    FN=data.$region.`date -Iseconds`
    if [ $? -eq 0 ];
    then
        mv $FN_TEMP $FN # filename (e.g., data.us-east-1.2017-01-01T01:01:01-0800)
        ln -sfn $FN data.$region.newest # update symlink

        NEWEST_TS=`head -20 $DATA_NEWEST | awk -F'\t' '{print $3}' | sort -r | head -1`
        echo "`$TS` $region finished. most recent entry is $NEWEST_TS."
    else
        echo "`$TS` $region something went wrong."
    fi
done

exit 0
