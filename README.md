# Enter dev environment
/opt/testaos/scripts/enter_build_environment.sh

# Install docker and enter ubuntu container
apt-get install docker.io
docker run -it --rm --mount type=bind,source=/opt/testaos,target=/opt ubuntu:jammy /opt/scripts/build_package.sh build-environment=bootstrap

# Create temporary dev environment
docker import /opt/testaos/packages/build-environment-boostrap.tar.gz build

# Remove all temporary packages
rm /opt/testaos/packages/*

# Use the temporary dev environment to build the real one
/opt/testaos/scripts/enter_build_environment.sh 'build_package.sh build-environment'

# Remove the temporary dev environment
docker image rm build

# Create the final build environment
docker import /opt/testaos/packages/build-environment-1.0.tar.gz build
