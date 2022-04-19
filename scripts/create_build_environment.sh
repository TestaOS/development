#!/bin/sh
set -e

#Create temp dir for the build system root
rm -rf /tmp/sysroot
mkdir /tmp/sysroot

#Setup skeleton directories
ln -s . /tmp/sysroot/usr
ln -s lib /tmp/sysroot/lib64
mkdir /tmp/sysroot/tmp
mkdir /tmp/sysroot/etc
echo 'root:x:0:' > /tmp/sysroot/etc/group
echo 'root::0:0:root:/:/bin/ash' > /tmp/sysroot/etc/passwd
mkdir -p /tmp/sysroot/etc/ssl/certs
wget -O /tmp/sysroot/etc/ssl/certs/ca-certificates.crt https://curl.se/ca/cacert.pem

#Install needed packages for development
packages="${1:-make-4.3 gcc-11.2.0 busybox-1.35.0 binutils-2.38 flex-2.6.4 kernel-headers-5.10 glibc-2.35 m4-1.4.19 perl-5.34.1 pkg-config-0.29.2 autoconf-2.69 bison-3.8.2 gettext-0.20.1 automake-1.16.5 coreutils-9.0 texinfo-6.7 cmake-3.22.3 bash-5.1.16 git-2.31.1}"

for package in $packages
do
	echo "Installing $package"
	tar -h -xf /opt/testaos/packages/$package.tar.gz -C /tmp/sysroot/
done

#Create docker image
echo 'Creating docker container'
tar -C /tmp/sysroot -c . | docker import - build

#Clean up
echo 'Cleaning up'
rm -rf /tmp/sysroot

echo 'Done!'
