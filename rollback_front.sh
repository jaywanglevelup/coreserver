#!/bin/bash - 
#===============================================================================
#
#          FILE:  portcheck.sh
# 
#         USAGE:  ./production_update.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Jay Wang (), 
#       COMPANY: PWRD
#       CREATED: 07/05/2011 09:39:56 AM CST
#      REVISION:  ---
#===============================================================================



serv='front'

bin_dir=/usr/local/bin/$serv
binbackup_dir=/home/rsyncuser/binbackup
rollback_logs=/root/rollback_logfile


printf "========================================\n" | tee -a $rollback_logs
if [ ! -d $binbackup_dir ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'ERROR: No binbackup dir!!!' | tee -a $rollback_logs
    exit 1
fi

cd $binbackup_dir
rollback_bin=$(ls -1tr | tail -1 )


printf "%s %s %s \n" "$(date +%Y-%m-%d\ %T)" \
    'Info: rollback binary md5sum: ' $(md5sum $rollback_bin) \
    | tee -a $rollback_logs

printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
    'Info: Kill old process!' | tee -a $rollback_logs


if pgrep -f '/usr/bin/python /usr/bin/supervisord'; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Supervisord is running, kill it first!' | tee -a $rollback_logs
    if ! pkill -9 -f  '/usr/bin/python /usr/bin/supervisord'; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'ERROR: Kill supervisord FAILED!' | tee -a $rollback_logs
        exit 1
    fi

    if pid=$(pgrep -f $bin_dir/$serv); then
        printf "%s %s %s. Kill it first.\n" "$(date +%Y-%m-%d\ %T)" \
            "$serv is running!! pid is: " "$pid" | tee -a $rollback_logs
        if ! pkill -f $bin_dir/$serv; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'ERROR: Kill old process FAILED!' | tee -a $rollback_logs
            exit 1
        fi
    else
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            "$serv is not running!! " | tee -a $rollback_logs
    fi
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Supervisord is not running!' | tee -a $rollback_logs

    if pid=$(pgrep -f $bin_dir/$serv); then
        printf "%s %s %s. Kill it first.\n" "$(date +%Y-%m-%d\ %T)" \
            "$serv is running!! pid is: " "$pid" | tee -a $rollback_logs
        if ! pkill -f $bin_dir/$serv; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'ERROR: Kill old process FAILED!' | tee -a $rollback_logs
            exit 1
        fi
    else
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            "$serv is not running!! " | tee -a $rollback_logs
    fi
fi
sleep 2
printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
    "Info: Replace $serv binary!" | tee -a $rollback_logs
install -v $rollback_bin $bin_dir/$serv | tee -a $rollback_logs

printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
    'Info: Start new process!' | tee -a $rollback_logs
if ! /usr/bin/python /usr/bin/supervisord; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'ERROR: Supervisord start failed!' | tee -a $rollback_logs
    cd /usr/local/var/log
    $bin_dir/$serv $bin_dir/$serv.xml 1> /dev/null 2>&1 &
fi

sleep 3

if new_pid=$(pgrep -f $bin_dir/$serv); then
    printf "%s %s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: New process id is:' $new_pid | tee -a $rollback_logs
    exit 0
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'ERROR: Start new process failed!' | tee -a $rollback_logs
    exit 1
fi
