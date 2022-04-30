#!/bin/sh

find /lib -name \*.a -exec bash -c "nm --defined-only {} 2>/dev/null | grep $1 && echo {}" \;
