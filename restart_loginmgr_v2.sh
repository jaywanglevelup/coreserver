#!/bin/bash
daemon_cmd='/usr/local/bin/loginmgr'
function stop_loginmgr {
    if ! pgrep -f "$daemon_cmd"; then
        printf "Error: loginmgr is not running!!\n"
        return 1
    fi
    
    if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
        printf "Info: supvisord is running! Kill it first\n"
        pkill -f '/usr/bin/python /usr/bin/supervisord'
        sleep 5
        if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
            printf "Warning: Supervisord is still running!! Try to kill daemon
            directly\n"
        fi
        printf "old pid: $(pgrep -f "$daemon_cmd")\n"
        pkill -f "$daemon_cmd"
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "Error: failed to kill loginmgr\n"
            return 2
        else
            return 0
        fi
    else
        printf "Info: supvisord is not running!\n"
        printf "old pid: $(pgrep -f "$daemon_cmd")\n"
        pkill -f "$daemon_cmd"
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "Error: failed to kill loginmgr\n"
            return 2
        else
            return 0
        fi
    fi
}

function start_loginmgr {
    if pgrep -f "$daemon_cmd"; then
        printf "Error: loginmgr is running!!try restart it!\n"
        return 1
    fi

    if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
        printf "warning supvisord is running!but daemon is dead! Start it
        manually\n"
        cd /usr/local/var/log/
        $daemon_cmd &
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "new pid: $(pgrep -f "$daemon_cmd")\n"
            return 0
        else
            printf "Error: loginmgr failed to start\n"
            return 2
        fi
    else
        printf "Info: start supvisord!"
        /usr/bin/python /usr/bin/supervisord &
        sleep 5
        if pgrep -f "$daemon_cmd"; then
            printf "new pid: $(pgrep -f "$daemon_cmd")\n"
            return 0
        else
            printf "supvisord bring back daemon failed, started it manually\n"
            cd /usr/local/var/log/
            $daemon_cmd &
            if pgrep -f "$daemon_cmd"; then
                printf "new pid: $(pgrep -f "$daemon_cmd")\n"
                return 0
            else
                printf "Error: loginmgr failed to start\n"
                return 2
            fi
        fi
    fi
}

lockfile=/var/run/$0.pid
if [ ! -e $lockfile ]; then
    trap "rm -f $lockfile; exit" INT TERM EXIT
    touch $lockfile
    if ! stop_loginmgr ; then
        printf "Error: stop process failed!! exit!"
        exit 1
    fi
    if ! start_loginmgr ; then
        printf "Error: start process failed!! exit!"
        exit 1
    fi
    rm $lockfile
    trap - INT TERM EXIT
else
    echo "$0 critical-section is already running"
fi
