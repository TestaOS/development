#!/bin/sh

docker run -it --rm -e PATH='/bin:/opt/scripts' --mount type=bind,source=/opt/testaos,target=/opt build nice -n19 bash
