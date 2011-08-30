#!/bin/bash
touch /var/run/restart_session.pid
if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf 'supvisord is running\n'
    printf "old pid: $(pgrep -f '/session')\n"
    pkill -f '/session'
    sleep 5
    if [ $(pgrep -f '/session' | wc -l) -eq 8 ]; then
        printf "new pid: $(pgrep -f '/session')\n"
    else
        printf "supvisord bring back daemon failed, started it manually\n"
        pkill -f '/session'
        sleep 3
        cd /usr/local/bin/session1/
        /usr/local/bin/session1/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session2/
        /usr/local/bin/session2/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session3/
        /usr/local/bin/session3/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session4/
        /usr/local/bin/session4/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session5/
        /usr/local/bin/session5/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session6/
        /usr/local/bin/session6/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session7/
        /usr/local/bin/session7/session /usr/local/bin/sm.xml >/dev/null 2>1&
        cd /usr/local/bin/session8/
        /usr/local/bin/session8/session /usr/local/bin/sm.xml >/dev/null 2>1&
        printf "new pid: $(pgrep -f '/session')\n"
    fi
else
    printf "old pid: $(pgrep -f '/session')\n"
    pkill -f './session'
    sleep 3
    cd /usr/local/bin/session1/
    /usr/local/bin/session1/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session2/
    /usr/local/bin/session2/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session3/
    /usr/local/bin/session3/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session4/
    /usr/local/bin/session4/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session5/
    /usr/local/bin/session5/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session6/
    /usr/local/bin/session6/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session7/
    /usr/local/bin/session7/session /usr/local/bin/sm.xml >/dev/null 2>1&
    cd /usr/local/bin/session8/
    /usr/local/bin/session8/session /usr/local/bin/sm.xml >/dev/null 2>1&
    printf "new pid: $(pgrep -f '/session')\n"
fi
rm /var/run/restart_session.pid
