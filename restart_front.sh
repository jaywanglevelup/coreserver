#!/bin/bash
touch /var/run/restart_front.pid
if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf 'supvisord is running\n'
    printf "old pid: $(pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml')\n"
    pkill -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml'
    sleep 5
    if pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml'; then
        printf "new pid: $(pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml')\n"
    else
        printf "supvisord bring back daemon failed, started it manually\n"
        cd /usr/local/var/log/
        /usr/local/bin/front/front /usr/local/bin/front/front.xml &
        printf "new pid: $(pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml')\n"
    fi
else
    printf "old pid: $(pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml')\n"
    cd /usr/local/var/log/
    pkill -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml'
    sleep 3
    /usr/local/bin/front/front /usr/local/bin/front/front.xml &
    printf "new pid: $(pgrep -f '/usr/local/bin/front/front /usr/local/bin/front/front.xml')\n"
fi
rm /var/run/restart_front.pid
