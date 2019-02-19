# aws-spot-price-history

A collection of scripts to pull the spot pricing history of Amazon Web Services
(AWS) Elastic Compute Cloud (EC2).

Currently these scripts will pull the history of all available instances' spot
prices and save them to a file. Every execution thereafter will grab only
the updated data.

## Usage

1. Grab the `ec2-api-tools.zip` from Amazon
2. Edit `pull.sh` and replace the environment variables `JAVA_HOME`
   `AWS_ACCESS_KEY`, and `AWS_SECRET_KEY` (or you can put your keys
    in the corresponding files: `aws_access.private` and `aws_secret.private`)
3. Run `pull.sh` and optionally install it in your `crontab`

The first run will grab all possible historic data (90 days, ~25 million
entries, ~2 GB uncompressed) across all 14 regions, so it will take a while.

## Data Format

Data will be stored in files named in the following format:

    data.REGION.YYYY-MM-DDThh:mm:ss±hh:mm

For example:

    data.us-east-1.2017-02-21T00:14:33-08:00
    data.ap-south-1.2017-03-15T15:52:17-07:00

See `ec2-describe-spot-price-history` for the format of the data file itself.

## TODO

* clean, format, and load data points into a time series database
* display graphs

## License

    Copyright 2019 Calvin Ardi
    
    Licensed under the Apache License, Version 2.0 (the "License");
    you may not use this file except in compliance with the License.
    You may obtain a copy of the License at
    
        http://www.apache.org/licenses/LICENSE-2.0
    
    Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
    WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.
