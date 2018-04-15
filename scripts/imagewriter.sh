#!/bin/bash

RUNNING_DIR="$(readlink -f $(dirname $0))"

cp -r "$RUNNING_DIR"/RosaImageWriter /tmp/RosaImageWriter
xdg-su -c /tmp/RosaImageWriter/RosaImageWriter
rm -rf /tmp/RosaImageWriter
