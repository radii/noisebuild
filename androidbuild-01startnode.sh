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

(
    echo buildnum=noisedroid-00002
    echo BUCKET=noisebuild
) > build.conf

. ./build.conf

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
