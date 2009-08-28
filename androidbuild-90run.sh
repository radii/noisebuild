#!/bin/bash

. ./common.inc
. ./build.conf

PATH=/opt/repo/bin:$PATH
cd /mnt/build/mydroid

. build/envsetup.sh
lunch htc_dream-eng
make

log "make exited with code $?"

tar czf $buildnum.tar.gz mydroid/out/target/product/dream/[^o]*
s3cmd put $buildnum.tar.gz s3://$BUCKET/
s3cmd put out/target/product/dream/system.img s3://$BUCKET/$buildnum-system.img
s3cmd put out/target/product/dream/ramdisk.img s3://$BUCKET/$buildnum-ramdisk.img
s3cmd put out/target/product/dream/userdata.img s3://$BUCKET/$buildnum-$userdata.img

log "deliverables published for $buildnum"
