#!/bin/sh

docker run -it --rm --mount type=bind,source=/opt/testaos,target=/opt build nice -n19 bash
