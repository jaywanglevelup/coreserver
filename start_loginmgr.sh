#!/bin/bash
daemon_cmd='/usr/local/bin/loginmgr'
function start_loginmgr {
    if pgrep -f "$daemon_cmd"; then
        printf "Error: loginmgr is running!!try restart it!\n"
        exit 1
    fi

    if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
        printf "warning supvisord is running!but daemon is dead! Start it
        manually\n"
        cd /usr/local/var/log/
        $daemon_cmd &
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "new pid: $(pgrep -f "$daemon_cmd")\n"
            exit 0
        else
            printf "Error: loginmgr failed to start\n"
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
            cd /usr/local/var/log/
            $daemon_cmd &
            if pgrep -f "$daemon_cmd"; then
                printf "new pid: $(pgrep -f "$daemon_cmd")\n"
                exit 0
            else
                printf "Error: loginmgr failed to start\n"
                exit 2
            fi
        fi
    fi
}

lockfile=/var/run/$0.pid
if [ ! -e $lockfile ]; then
    trap "rm -f $lockfile; exit" INT TERM EXIT
    touch $lockfile
    start_loginmgr
    rm $lockfile
    trap - INT TERM EXIT
else
    echo "$0 critical-section is already running"
fi
