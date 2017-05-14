#!/bin/sh
#set -x

host_name=`hostname`
cat machine.cfg | grep $host_name | awk -F " "  '{print $2"_nightly"}'
