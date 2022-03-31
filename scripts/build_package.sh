#!/bin/sh
set -e
#THIS SCRIPT SHOULD BE RUN INSIDE THE BUIILD DOCKER CONTAINER!

#Optimize for maximum binary speed and strip binary for minimal size
export CFLAGS='-O3 -s -w -fPIC'
export CXXFLAGS='-O3 -s -w -fPIC'
export LDFLAGS='-s -w'

#Read package build file
PACKAGE=$1
VERSION="${2:-stable}"

#source $FILE
RECIPE="/opt/recipes/$PACKAGE/$VERSION/recipe"
if [ ! -f $RECIPE ]; then
	echo "Specified package does not exist"
	exit 1;
fi

. "$RECIPE"

echo "Building package $PACKAGE-$VERSION"
DESTDIR=/tmp/package
rm -rf "$DESTDIR"

#Fetch dependencies
echo 'Loading dependencies...'

#CHECK IF EACH DEPENDENCY EXIST LOCALLY. IF NOT THEN DOWNLOAD!
#IF YOU CANT DOWNLOAD, THEN FAIL HERE!!

for DEPENDENCY in $DEPENDENCIES; do
	echo $DEPENDENCY
	tar -h -xf "/opt/packages/$DEPENDENCY.tar.gz" -C /
done

mkdir -p /tmp/source
cd /tmp/source

mkdir -p /opt/cache
if [ ! -f "/opt/cache/$FILENAME" ]; then
	echo 'Downloading source...'
	wget -O "/opt/cache/$FILENAME" "$SOURCE"
fi

echo 'Unpacking source...'
tar xf "/opt/cache/$FILENAME" -C /tmp/source

#Run build function
cd "$DIRECTORY"
if type 'build' 2>/dev/null | grep -q 'function'; then
	build
else
        ./configure \
        --prefix=/usr \
        --enable-static \
        --disable-shared

        make -j$(nproc) V=1
fi

#Run install function
if type 'install' 2>/dev/null | grep -q 'function'; then
	install
else
	make install DESTDIR="$DESTDIR"
fi

#Create the tar package
if [ ! -d "$DESTDIR" ]; then
	echo 'Nothing to compress, aborting.'
	exit 1
fi

cd "$DESTDIR"
echo 'Compressing package...'
tar zcf "/opt/packages/$PACKAGE-$VERSION.tar.gz" .

echo 'Done!'
