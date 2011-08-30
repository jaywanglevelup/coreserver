#!/bin/bash
if [ $(netstat -ntlo | grep 11211 | wc -l) -lt 2 ]; then 
    echo 'memcached down'
    pkill -f '/usr/local/bin/memcached'
    /usr/local/bin/memcached -d -p 11211 -m 1024 -c 1024 -u nobody -P /var/run/memcached/memcached-11211.pid
fi

if ! pgrep -f '/usr/local/bin/memcached' ; then  
    echo 'memcached down' 
    pkill -f '/usr/local/bin/memcached' 
    /usr/local/bin/memcached -d -p 11211 -m 1024 -c 1024 -u nobody -P /var/run/memcached/memcached-11211.pid
fi
