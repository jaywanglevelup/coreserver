#!/bin/bash
touch /var/run/restart_corecenter.pid
if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf 'supvisord is running\n'
    printf "old pid: $(pgrep -f '/usr/local/bin/corecenter')\n"
    pkill -f '/usr/local/bin/corecenter'
    sleep 5
    if pgrep -f '/usr/local/bin/corecenter'; then
        printf "new pid: $(pgrep -f '/usr/local/bin/corecenter')\n"
    else
        printf "supvisord bring back daemon failed, started it manually\n"
        cd /usr/local/var/log/
        /usr/local/bin/corecenter &
        printf "new pid: $(pgrep -f '/usr/local/bin/corecenter')\n"
    fi
else
    printf "old pid: $(pgrep -f '/usr/local/bin/corecenter')\n"
    cd /usr/local/var/log/
    pkill -f '/usr/local/bin/corecenter'
    sleep 3
    /usr/local/bin/corecenter &
    printf "new pid: $(pgrep -f '/usr/local/bin/corecenter')\n"
fi
rm /var/run/restart_corecenter.pid
