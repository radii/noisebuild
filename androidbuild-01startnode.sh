#!/bin/bash

function log() {
    echo "[`date +%T.%N|cut -c1-12`] $*"
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

set -e -x

sshopts="-i ~/.ec2/id_rsa-gsg-keypair"

tmp=$(mktemp -d)
cd $tmp

ec2-run-instances ami-ed46a784 -k gsg-keypair | tee run-instances.out
instance=$(awk '$1 == "INSTANCE" {print $2}' run-instances.out)
hostname=$(awk '$1 == "INSTANCE" {print $4}' run-instances.out)

log "Started $instance at hostname $hostname"

# XXX wait for node to be up

ec2-get-console-output $instance | tee console.out

# XXX verify host key fingerprints

scp $sshopts androidbuild-10setup.sh root@$hostname:
log "setup $hostname start"
ssh $sshopts root@$hostname ./androidbuild-10setup.sh
log "setup $hostname done"
scp $sshopts androidbuild-20usersetup.sh build@$hostname:
log "usersetup $hostname start"
ssh $sshopts build@$hostname ./androidbuild-20usersetup.sh
log "usersetup $hostname done"
scp $sshopts androidbuild-90run.sh build@$hostname
log "run $hostname start"
ssh $sshopts build@$hostname ./androidbiuld-90run.sh
log "run $hostname done"

#log "shutting down $hostname"
#ec2-terminate-instances $instance
#log "$0 done!"
