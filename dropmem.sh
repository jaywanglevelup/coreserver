#!/bin/bash
if [ $(free -g |grep Mem |  awk '{print $4}') -lt 1 ]; then 
    echo 1 > /proc/sys/vm/drop_caches 
fi
