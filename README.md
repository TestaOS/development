# Enter dev environment
/opt/testaos/scripts/enter_build_environment.sh

# Create temporary dev environment
apt-get install docker.io
docker run -it --rm --mount type=bind,source=/opt/testaos,target=/opt ubuntu bash
apt-get update
apt-get install -y build-essential wget m4 bison

/opt/scripts/build_package.sh gmp
/opt/scripts/build_package.sh mpfr
/opt/scripts/build_package.sh mpc
/opt/scripts/build_package.sh gcc=11.2.0-minimal

/opt/scripts/build_package.sh busybox

/opt/scripts/build_package.sh gawk
/opt/scripts/build_package.sh libffi
/opt/scripts/build_package.sh make
/opt/scripts/build_package.sh perl
/opt/scripts/build_package.sh zlib
/opt/scripts/build_package.sh openssl
/opt/scripts/build_package.sh python
/opt/scripts/build_package.sh grep
/opt/scripts/build_package.sh m4
/opt/scripts/build_package.sh bison
/opt/scripts/build_package.sh flex
/opt/scripts/build_package.sh rsync

/opt/scripts/build_package.sh kernel-headers=5.10

/opt/scripts/build_package.sh glibc

/opt/scripts/build_package.sh texinfo
/opt/scripts/build_package.sh binutils

/opt/scripts/build_package.sh bash

/opt/testaos/scripts/create_build_environment.sh 'sysroot-base=1.0 busybox=1.35.0 gcc-11.2.0=minimal glibc=2.35 binutils=2.38 kernel-headers=5.10 bash=5.1.16'

# Remove all temporary packages
