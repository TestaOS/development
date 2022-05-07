#!/bin/bash

COMMAND="${1:-nice -n19 bash}"

docker run -it --rm --dns 8.8.8.8 -e PATH='/bin:/opt/scripts' --mount type=bind,source=/opt/testaos,target=/opt build $COMMAND
