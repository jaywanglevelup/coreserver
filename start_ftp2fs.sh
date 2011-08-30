#!/bin/bash
if lsof /root/bin/ftp2fs_rsync.sh ; then 
    echo  "running rsync" 
    exit 0
else 
    /root/bin/ftp2fs_rsync.sh > /dev/null
    exit 0
fi
