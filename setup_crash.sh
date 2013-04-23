#!/bin/bash

VERSION=`uname -r`
BASE_PATH="http://debuginfo.centos.org/6/x86_64/"


echo "Retrieving kernel debuginfo packages required for 'crash' analysis..."

mkdir /tmp/crash/
cd /tmp/crash/ || exit 2

wget "http://debuginfo.centos.org/6/x86_64/kernel-debuginfo-${VERSION}.rpm"
if [ $? -ne 0 ]
then
    echo "Downloading http://debuginfo.centos.org/6/x86_64/kernel-debuginfo-${VERSION}.rpm failed. It's possible the mirror is down, or for some reason that kernel has no debuginfo. "
    exit 2
fi
wget "http://debuginfo.centos.org/6/x86_64/kernel-debuginfo-common-x86_64-${VERSION}.rpm"
if [ $? -ne 0 ]
then
    echo "Downloading http://debuginfo.centos.org/6/x86_64/kernel-debuginfo-common-x86_64-${VERSION}.rpm failed. It's possible the mirror is down, or for some reason that kernel has no debuginfo. "
    exit 2
fi

echo "Installing vmlinux from debug packages..."
rpm -i /tmp/crash/kernel-debuginfo*

echo "Installing 'crash'..."
yum install -y crash

echo "Done."

echo "Now run:"

SYSTEM_MAP=`ls -l /boot/System.map* | head -n 1 | awk '{print $NF}'`
echo
echo "crash ${SYSTEM_MAP} /usr/lib/debug/lib/modules/${VERSION}/vmlinux /var/crash/<your crash file>"
