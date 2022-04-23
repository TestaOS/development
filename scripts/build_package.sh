#!/bin/sh
set -e
#THIS SCRIPT SHOULD BE RUN INSIDE THE BUILD DOCKER CONTAINER!

#Optimize for maximum binary speed and strip binary for minimal size
export CFLAGS='-O3 -s -w -fPIC -static-libstdc++ -static-libgcc'
export CXXFLAGS='-O3 -s -w -fPIC -static-libstdc++ -static-libgcc'
export LDFLAGS='-s -w'

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

		echo 'Downloading source...'
		wget -O "$FILE" "$1"

        	echo 'Unpacking source...'
        	tar xf "$FILE" -C $SRCDIR
	fi
}

#Read package build file
PACKAGE=$1
VERSION="${2:-stable}"

#source $FILE
ROOT="/opt/recipes/$PACKAGE/$VERSION"
RECIPE="$ROOT/recipe"
if [ ! -f $RECIPE ]; then
	echo "Specified package does not exist"
	exit 1;
fi

. "$RECIPE"

echo "Building package $PACKAGE-$VERSION"
DESTDIR='/tmp/package'
rm -rf "$DESTDIR"

#Fetch dependencies
echo 'Loading dependencies...'

#CHECK IF EACH DEPENDENCY EXIST LOCALLY. IF NOT THEN DOWNLOAD!
#IF YOU CANT DOWNLOAD, THEN FAIL HERE!!

for DEPENDENCY in $DEPENDENCIES; do
	echo $DEPENDENCY
	tar -h -xf "/opt/packages/$DEPENDENCY.tar.gz" -C /
done

CACHEDIR='/opt/cache'
SRCDIR='/tmp/source'
rm -rf "$SRCDIR"
mkdir -p $SRCDIR

mkdir -p $CACHEDIR
if [ ! -f "$CACHEDIR/$FILENAME" ]; then

	#Check if source is an array
	if [ "${#SOURCE[@]}" -gt "1" ]; then

		for DOWNLOAD in "${SOURCE[@]}"; do
			download $DOWNLOAD
		done
	else
		download $SOURCE "$CACHEDIR/$FILENAME"
	fi
else
	echo 'Unpacking source...'
	tar xf "$CACHEDIR/$FILENAME" -C $SRCDIR
fi

#If cache does not exit, pack source dir
if [ ! -f "$CACHEDIR/$FILENAME" ]; then
	echo 'Saving source to cache...'
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
echo 'Compressing package...'
tar zcf "/opt/packages/$PACKAGE-$VERSION.tar.gz" .

echo 'Done!'
