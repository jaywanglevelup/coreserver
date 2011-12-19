#!/bin/bash
daemon_cmd='/session'
function stop_session {
    if ! pgrep -f "$daemon_cmd"; then
        printf "Error: session is not running!!\n"
        exit 1
    fi
    
    if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
        printf "Info: supvisord is running! Kill it first\n"
        pkill -f '/usr/bin/python /usr/bin/supervisord'
        sleep 2
        if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
            printf "Warning: Supervisord is still running!! Try to kill daemon
            directly\n"
        fi
        printf "old pid: $(pgrep -f "$daemon_cmd")\n"
        pkill -f "$daemon_cmd"
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "Error: failed to kill session\n"
            exit 2
        else
            exit 0
        fi
    else
        printf "Info: supvisord is not running!\n"
        printf "old pid: $(pgrep -f "$daemon_cmd")\n"
        pkill -f "$daemon_cmd"
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "Error: failed to kill session\n"
            exit 2
        else
            exit 0
        fi
    fi
}

lockfile=/var/run/$0.pid
if [ ! -e $lockfile ]; then
    trap "rm -f $lockfile; exit" INT TERM EXIT
    touch $lockfile
    stop_session
    rm $lockfile
    trap - INT TERM EXIT
else
    echo "$0 critical-section is already running"
fi
