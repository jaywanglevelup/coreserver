#!/bin/bash
daemon_cmd='/session'
function run_sessions {
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
}

function start_session {
    if pgrep -f "$daemon_cmd"; then
        printf "Error: session is running!!try restart it!\n"
        exit 1
    fi

    if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
        printf "warning supvisord is running!but daemon is dead! Start it
        manually\n"
        run_sessions
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "new pid: $(pgrep -f "$daemon_cmd")\n"
            exit 0
        else
            printf "Error: session failed to start\n"
            exit 2
        fi
    else
        printf "Info: start supvisord!"
        /usr/bin/python /usr/bin/supervisord &
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "new pid: $(pgrep -f "$daemon_cmd")\n"
            exit 0
        else
            printf "supvisord bring back daemon failed, started it manually\n"
            run_sessions
            if pgrep -f "$daemon_cmd"; then
                printf "new pid: $(pgrep -f "$daemon_cmd")\n"
                exit 0
            else
                printf "Error: session failed to start\n"
                exit 2
            fi
        fi
    fi
}

lockfile=/var/run/$0.pid
if [ ! -e $lockfile ]; then
    trap "rm -f $lockfile; exit" INT TERM EXIT
    touch $lockfile
    start_session
    rm $lockfile
    trap - INT TERM EXIT
else
    echo "$0 critical-section is already running"
fi
