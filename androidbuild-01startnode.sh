#!/bin/bash

. ./common.inc

function instance_hostname() {
    inst=$1
    ec2-describe-instances $inst | tee describe-instances.out | \
	awk '$1 == "INSTANCE" {print $4}'
}

test -z "$JAVA_HOME" && export JAVA_HOME=/usr/lib/jvm/java-6-sun

test -z "$EC2_PRIVATE_KEY" && {
    echo "EC2_PRIVATE_KEY must be set" >&2
    exit 1
}
test -z "$EC2_CERT" && {
    echo "EC2_CERT must be set" >&2
    exit 1
}

set -e

sshopts="-i $HOME/.ec2/id_rsa-gsg-keypair"

P=$(pwd)
tmp=$(mktemp -d)
cd $tmp

test -z "$BUCKET" && BUCKET=noisebuild

# XXX this is a race, ideally would have a web service providing build
# numbers
buildnum=$(curl -s http://$BUCKET.s3.amazonaws.com/lastbuild.txt)
[ -z "$buildnum" ] && buildnum=noisedroid-0000
buildnum=$(echo $buildnum | perl -pe 's/(\d+)$/sprintf("%0*d", length($1), $1+1)/e')
echo $buildnum > lastbuild.txt
s3cmd put -P lastbuild.txt s3://$BUCKET/lastbuild.txt

(
    echo buildnum=$buildnum
    echo BUCKET=$BUCKET
) > build.conf

# http://alestic.com       32-bit server       64-bit server
# Ubuntu 9.04 Jaunty       ami-ed46a784        ami-5b46a732
# Debian 5.0 Lenny         ami-ff46a796        ami-2d46a744 
# Debian Squeeze           ami-fb46a792        ami-2946a740
# instance type            m1.small c1.medium  m1.large c1.xlarge
#
# m1.small   $0.10/hr 1.7GB x86    1 EC2 Compute Unit  (1 core 1 ECU)
# c1.medium  $0.20/hr 1.7GB x86    5 EC2 Compute Units (2 cores 2.5 ECUs)
# m1.large   $0.40/hr 7.5GB x86_64 4 EC2 Compute Units (2 cores 2 ECUs)
# c1.xlarge  $0.80/hr 7GB   x86_64 20 EC2 Compute Units (8 cores 2.5 ECUs)

ec2-run-instances -t c1.medium ami-ed46a784 -k gsg-keypair | tee run-instances.out
instance=$(awk '$1 == "INSTANCE" {print $2}' run-instances.out)

log "Started $instance"

hostname=$(instance_hostname $instance)
while [[ "$hostname" == "pending" ]]; do
    sleep 5
    hostname=$(instance_hostname $instance)
    printf .
done
echo

log "Got hostname $hostname"

ec2-get-console-output $instance | tee console.out

# XXX verify host key fingerprints

scp $sshopts $P/androidbuild-10setup.sh root@$hostname:
log "setup $hostname start"
ssh $sshopts root@$hostname ./androidbuild-10setup.sh
log "setup $hostname done"
scp $sshopts $P/androidbuild-20usersetup.sh $P/common.inc build.conf ~/.s3cfg \
        build@$hostname:
log "usersetup $hostname start"
ssh $sshopts build@$hostname ./androidbuild-20usersetup.sh
log "usersetup $hostname done"
scp $sshopts $P/androidbuild-90run.sh build@$hostname:
log "run $hostname start"
ssh $sshopts build@$hostname ./androidbuild-90run.sh
log "run $hostname done"

#log "shutting down $hostname"
#ec2-terminate-instances $instance
#log "$0 done!"
