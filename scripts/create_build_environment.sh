#!/bin/bash
set -e

#Create temp dir for the build system root
rm -rf /tmp/sysroot
mkdir /tmp/sysroot

#Install needed packages for development
PACKAGES="${1:-sysroot-base=1.0 make=4.3 gcc=11.2.0 busybox=1.35.0 binutils=2.38 flex=2.6.4 kernel-headers=5.10 glibc=2.35 m4=1.4.19 perl=5.34.1 pkg-config=0.29.2 autoconf=2.69 bison=3.8.2 gettext=0.20.1 automake=1.16.5 coreutils=9.0 texinfo=6.7 cmake=3.22.3 bash=5.1.16 git=2.31.1 wget=1.21.3}"

for PACKAGE in $PACKAGES
do
	NAME="${PACKAGE%%=*}"
	VERSION="${PACKAGE##*=}"

	FILENAME="/opt/testaos/packages/$NAME-$VERSION.tar.gz"

	if [ ! -f "$FILENAME" ]; then
		echo "Package $PACKAGE does not exist, compiling..."

		/opt/testaos/scripts/enter_build_environment.sh "/opt/scripts/build_package.sh $PACKAGE"
	fi

	echo "Unpacking $NAME-$VERSION..."
	tar -h -xf $FILENAME -C /tmp/sysroot/
done

#Create docker image
echo 'Creating docker container...'
tar -C /tmp/sysroot -c . | docker import - build

#Clean up
echo 'Cleaning up...'
rm -rf /tmp/sysroot

echo 'Done!'
