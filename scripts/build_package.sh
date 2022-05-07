#!/bin/bash
set -e

#Optimize for maximum binary speed and strip binary for minimal size
export CFLAGS='-O3 -fPIC -static-libstdc++ -static-libgcc'
export CXXFLAGS='-O3 -fPIC -static-libstdc++ -static-libgcc'
export LDFLAGS=''

export CGO_CPPFLAGS="${CXXFLAGS}"
export CGO_CFLAGS="${CFLAGS}"
export CGO_CXXFLAGS="${CXXFLAGS}"
export CGO_LDFLAGS="${LDFLAGS}"

#Functions

#Download and unpack source code
download() {
	if [[ $1 == git+* ]]; then

		COMMIT="${1##*#}"
		GIT="${1:4}"
		GIT="${GIT%%#*}"

		git clone -n $GIT "$SRCDIR/$COMMIT"
		cd "$SRCDIR/$COMMIT"
		git checkout $COMMIT
	else
		FILE="${2:-$(mktemp)}"

		echo "Downloading source $FILE..."
		wget --no-check-certificate -O "$FILE" "$1"

        	echo "Unpacking source $FILE..."
        	tar xf "$FILE" -C $SRCDIR
	fi
}

PACKAGE="${1%%=*}"
VERSION="${1##*=}"

if [ "$VERSION" = "$PACKAGE" ]; then
	VERSION='stable'
fi

#source $FILE
ROOT="/opt/recipes/$PACKAGE/$VERSION"
RECIPE="$ROOT/recipe"
if [ ! -f $RECIPE ]; then
	echo "Package $1 does not exist"
	exit 1;
fi

#Read package build file
. "$RECIPE"

echo "Building package $1"

if type 'before' 2>/dev/null | grep -q 'function'; then
        before
fi

DESTDIR='/tmp/package'
rm -rf "$DESTDIR"

if [ -z "$SKIP_DEPENDENCIES" ]; then
	#Fetch dependencies
	echo "Loading dependencies for $1..."

	#CHECK IF EACH DEPENDENCY EXIST LOCALLY. IF NOT THEN DOWNLOAD!
	#IF YOU CANT DOWNLOAD, THEN TRY TO BUILD IT!

	for DEPENDENCY in $DEPENDENCIES; do

		PACK="${DEPENDENCY/=/-}"

		if [ ! -f "/opt/packages/$PACK.tar.gz" ]; then
			echo "Dependency $DEPENDENCY does not exist locally. Downloading..."
			#wget....

			echo "Download failed. Trying to build package $DEPENDENCY from source..."
			/opt/scripts/build_package.sh $DEPENDENCY
		fi

		echo "Unpacking $DEPENDENCY..."
		tar -h -xf "/opt/packages/$PACK.tar.gz" -C /
	done
fi

CACHEDIR='/opt/cache'
SRCDIR='/tmp/source'
rm -rf "$SRCDIR"
mkdir -p $SRCDIR
mkdir -p $CACHEDIR

if [ ! -f "$CACHEDIR/$FILENAME" ]; then

	#Check if source is an array
	if [ "${#SOURCE[@]}" -gt 1 ]; then
		for DL in "${SOURCE[@]}"; do
			download $DL
		done
	else
		download $SOURCE "$CACHEDIR/$FILENAME"
	fi
else
	echo "Unpacking source $FILENAME..."
	tar xf "$CACHEDIR/$FILENAME" -C $SRCDIR
fi

#If cache does not exit, pack source dir
if [ ! -f "$CACHEDIR/$FILENAME" ]; then
	echo "Saving source $FILENAME to cache..."
	tar zcf "$CACHEDIR/$FILENAME" -C $SRCDIR .
fi

#Run build function
cd "$SRCDIR/$DIRECTORY"

if type 'build' 2>/dev/null | grep -q 'function'; then
	build
else
        ./configure \
        --prefix=/usr \
        --enable-static \
        --disable-shared

        make -j$(nproc) V=1
fi

#Run package function
cd "$SRCDIR/$DIRECTORY"

if type 'package' 2>/dev/null | grep -q 'function'; then
	package
else
	make install DESTDIR="$DESTDIR"
fi

#Create the tar package
if [ ! -d "$DESTDIR" ]; then
	echo 'Nothing to compress, aborting.'
	exit 1
fi

cd "$DESTDIR"
mkdir -p /opt/packages
echo "Compressing package $1..."
tar zcf "/opt/packages/$PACKAGE-$VERSION.tar.gz" .

echo "Done with $1"
