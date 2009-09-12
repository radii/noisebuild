#!/bin/bash

set -e

export DEBIAN_FRONTEND=teletype

apt-get update

# accept the Sun DLJ (wankers)
for b in bin jdk jre; do
    echo "sun-java5-$b shared/accepted-sun-dlj-v1-1 boolean true"
done | debconf-set-selections

apt-get -y install git-core gnupg flex bison gperf build-essential zip \
    curl sun-java5-jdk zlib1g-dev gcc-multilib g++-multilib \
    libncurses5-dev x11proto-core-dev libx11-dev \
    libreadline5-dev libz-dev

update-java-alternatives -s java-1.5.0-sun || true

apt-get -y install s3cmd

mkdir -p /opt/repo/bin
curl http://android.git.kernel.org/repo > /opt/repo/bin/repo
chmod +x /opt/repo/bin/repo
md5sum /opt/repo/bin/repo

[ -d ~build ] || adduser --disabled-password --gecos 'Noisedroid Buildbot' build

mkdir -p ~build/.ssh
cp /root/.ssh/authorized_keys ~build/.ssh
chown -R build ~build/.ssh
chmod -R u+rX,go-rwx ~build/.ssh

mkdir -p /mnt/build
chown build /mnt/build
