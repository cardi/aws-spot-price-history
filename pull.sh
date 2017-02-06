#!/usr/bin/env bash

# Filename: pull.sh
# 
# Copyright 2017 Calvin Ardi
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
# 5 0 * * * /path/to/aws-spot-price-history/test.sh >> /path/to/aws-spot-price-history/log.txt

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

# do we already have data?
if [ -e "data.newest" ];
then
    # grab the most recent entry timestamp (e.g., 2017-02-02T11:45:34-0800)
    NEWEST_TS=`head -20 data.newest | awk -F'\t' '{print $3}' | sort -r | head -1`
    echo "existing data found: most recent timestamp is $NEWEST_TS"
else
    unset NEWEST_TS
    echo "no existing data found, starting from the beginning (otherwise symlink 'data.newest' to the most recent file)"
    echo "note: the initial data pull can take a while (~1 hour)"
fi

# we can only grab the last 90 days of data: if the most recent timestamp is
# more than 90 days ago then we're essentially starting from scratch.
FN_TEMP=data.`date -Iseconds`.temp
echo "starting data refresh on `date -Iseconds`."
if [ ! -z "$NEWEST_TS" ];
then
    # only get the diff, but there will be some overlap regardless
    $EC2_HOME/bin/ec2-describe-spot-price-history \
        --start-time $NEWEST_TS \
        > $FN_TEMP
else
    $EC2_HOME/bin/ec2-describe-spot-price-history \
        > $FN_TEMP
fi

# if the data refresh is finished, then move the files around and update
# symlinks.
FN=data.`date -Iseconds`
if [ $? -eq 0 ];
then
    mv $FN_TEMP $FN # filename (e.g., data.2017-01-01T01:01:01-0800)
    ln -sfn $FN data.newest # update symlink

    NEWEST_TS=`head -20 data.newest | awk -F'\t' '{print $3}' | sort -r | head -1`
    echo "finished on `date -Iseconds`. most recent entry is $NEWEST_TS."
else
    echo "something went wrong."
fi

exit 0
