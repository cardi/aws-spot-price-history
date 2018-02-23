#!/usr/bin/env bash

# Filename: compress.sh
#
# Description: Compresses, in parallel, all data files except for the most
# recent one. Uses `parallel` for parallelization and `xz` for compression.
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

# number of jobs for `parallel` to run
JOBS=10
# number of threads for `xz` to use
THREADS=2

# to be crontab compatible
cd $(dirname $0)

REGIONS=( ap-south-1 eu-west-3 eu-west-2 eu-west-1 ap-northeast-2 ap-northeast-1 sa-east-1
    ca-central-1 ap-southeast-1 ap-southeast-2 eu-central-1 us-east-1 us-east-2
    us-west-1 us-west-2 )

TS="date -Iseconds"

for region in "${REGIONS[@]}"
do
    echo "`$TS` $region starting"

    # get all data files per region except for the most recent one
    find . -type f \( -iname "data.$region.[0-9]*" -a -not -iname "*.xz" \) \
        | sort -r \
        | tail -n +2 \
        | parallel -j$JOBS "xz --threads=$THREADS {}"
done

exit 0
