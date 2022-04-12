#!/bin/sh
set -e

#Create temp dir for the system root
rm -rf /tmp/sysroot
mkdir /tmp/sysroot

#Install needed packages for sysroot
packages='sysroot-base-1.0 busybox-1.35.0 glibc-2.35 linux-kernel-mt8371-5.15 iw-5.0.1 wpa-supplicant-2.10'

for package in $packages
do
	echo "Installing $package"
	tar -h -xf /opt/testaos/packages/$package.tar.gz -C /tmp/sysroot/
done

#Create release package
echo 'Create release package'
tar zcf /opt/testaos/packages/testaos-mt8371-1.0.tar.gz -C /tmp/sysroot .

#Clean up
echo 'Cleaning up'
rm -rf /tmp/sysroot

echo 'Done!'
