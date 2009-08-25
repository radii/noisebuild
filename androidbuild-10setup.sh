#!/bin/bash

set -e -x

apt-get update
export DEBIAN_FRONTEND=noninteractive
apt-get -y install git-core gnupg flex bison gperf build-essential zip \
    curl sun-java5-jdk zlib1g-dev gcc-multilib g++-multilib \
    lib32ncurses5-dev ia32-libs x11proto-core-dev libx11-dev \
    lib32readline5-dev lib32z-dev

update-java-alternatives -s java-1.5.0-sun

mkdir -p /opt/repo/bin
curl http://android.git.kernel.org/repo > /opt/repo/bin/repo
chmod +x /opt/repo/bin/repo
md5sum /opt/repo/bin/repo

adduser --disabled-password --gecos 'Android Buildbot' build
mkdir -p ~build/.ssh
cp /root/.ssh/authorized_keys ~build/.ssh
chown -R build ~build/.ssh
chmod -R u+rX,go-rwx ~build/.ssh