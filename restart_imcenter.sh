#!/bin/bash
touch /var/run/restart_imcenter.pid
if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf 'supvisord is running\n'
    printf "old pid: $(pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml')\n"
    pkill -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml'
    sleep 3
    if pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml'; then
        printf "new pid: $(pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml')\n"
    else
        printf "supvisord bring back daemon failed, started it manually\n"
        cd /usr/local/var/log/
        /usr/local/bin/imcenter /usr/local/bin/imcenter.xml &
        printf "new pid: $(pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml')\n"
    fi
else
    printf "old pid: $(pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml')\n"
    cd /usr/local/var/log/
    pkill -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml'
    sleep 3
    /usr/local/bin/imcenter /usr/local/bin/imcenter.xml &
    printf "new pid: $(pgrep -f '/usr/local/bin/imcenter /usr/local/bin/imcenter.xml')\n"
fi
rm /var/run/restart_imcenter.pid
