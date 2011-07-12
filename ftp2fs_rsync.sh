#!/bin/bash - 
#===============================================================================
#
#          FILE:  cdn_rsync.sh
# 
#         USAGE:  ./ft22fs_rsync.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Jay Wang (), 
#       COMPANY: PWRD
#       CREATED: 07/07/2011 03:49:38 PM CST
#      REVISION:  ---
#===============================================================================

# rsync from management to cc-staging-corecenter
# Put this file on cc-management server (ftp). 
# It will auto run rsync to cc-staging-corecenter server, if there is any
# update
# 

ROOT_DIR=/home/shftp/COREClient
# rsync will start in 5 minutes after update this file
rsync_switch=$ROOT_DIR/rsync_switch.txt
rsynced_dir=$ROOT_DIR/rsynced
check_switch=/root/rsync_switch.txt
rsync_passwd=/root/rsync_passwd
rsync_logs=/root/rsync_logfile

function do_rsync {
    if [ ! -s $rsync_passwd ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing or no password, rsync failed!!'| tee -a $rsync_logs
        exit 1
    fi

    if [ ! -d $ROOT_DIR/Games ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing source dir, rsync failed!!!' | tee -a $rsync_logs
        exit 1
    fi
    
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Updating....!!!'\
        | tee -a $rsync_logs

    if ! rsync -n rsyncuser@172.29.31.18::core-game \ 
        --password-file $rsync_passwd ; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Error: Rsync test failed!!'\
            | tee -a $rsync_logs
        exit 1
    fi

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" "Rsync $ROOT_DIR/Games start!!" \
        | tee -a $rsync_logs

    rsync -avc --progress $ROOT_DIR/Games rsyncuser@172.29.31.18::core-game \
        --password-file $rsync_passwd | tee -a $rsync_logs
    
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        "Rsync $ROOT_DIR/Games Done!!" \
        | tee -a $rsync_logs
    
    rsync -avc --progress $rsync_switch rsyncuser@172.29.31.18::core-game \
        --password-file $rsync_passwd | tee -a $rsync_logs

    printf "%s %s \n" 'update check_switch file' | tee -a $rsync_logs
    rsync -av $rsync_switch $check_switch

    mv -v $ROOT_DIR/Games/* $rsynced_dir/
    mkdir -v  $ROOT_DIR/Games/{BOI,ESO,FW,HOTK,JD,LOMA,PWI,RH,updates}
    chown -v shftp:shftp -R $ROOT_DIR/Games/
}

if [ ! -e $rsync_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Error: No rsync_switch file on ftp server. Exit!!' | tee -a $rsync_logs
    exit 1
fi

if [ ! -d $rsynced_dir ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
    'No rsynced_dir, Create it first!!' | tee -a $rsync_logs
    mkdir -p -v $rsynced_dir
    chown -v shftp:shftp -R $rsynced_dir
fi


if [ ! -e $check_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'No check_switch file, the first time for rsync!!' | tee -a $rsync_logs
    do_rsync
    exit 0
fi

if [ $rsync_switch -nt $check_switch ]; then
    do_rsync
    exit 0
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Nothing need to update' | tee -a $rsync_logs
    exit 0
fi
