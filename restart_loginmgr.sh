#!/bin/bash
touch /var/run/restart_loginmgr.pid
if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf 'supvisord is running\n'
    printf "old pid: $(pgrep -f '/usr/local/bin/loginmgr')\n"
    pkill -f '/usr/local/bin/loginmgr'
    sleep 5
    if pgrep -f '/usr/local/bin/loginmgr'; then
        printf "new pid: $(pgrep -f '/usr/local/bin/loginmgr')\n"
    else
        printf "supvisord bring back daemon failed, started it manually\n"
        cd /usr/local/var/log/
        /usr/local/bin/loginmgr &
        printf "new pid: $(pgrep -f '/usr/local/bin/loginmgr')\n"
    fi
else
    printf "old pid: $(pgrep -f '/usr/local/bin/loginmgr')\n"
    cd /usr/local/var/log/
    pkill -f '/usr/local/bin/loginmgr'
    sleep 3
    /usr/local/bin/loginmgr &
    printf "new pid: $(pgrep -f '/usr/local/bin/loginmgr')\n"
fi
rm /var/run/restart_loginmgr.pid
