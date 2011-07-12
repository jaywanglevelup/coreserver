#!/bin/bash - 
#===============================================================================
#
#          FILE:  cdn_rsync.sh
# 
#         USAGE:  ./fs2cdn_rsync.sh 
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

# rsync from cc-staging-corecenter to CDN
# Put this file on cc-staging-corecenter
# It will auto run rsync to CDN server, if there is any update
# 

ROOT_DIR=/fileserver/COREClient
# rsync will start in 5 minutes after update this file
rsync_switch=$ROOT_DIR/rsync_switch.txt
rsynced_dir=$ROOT_DIR/rsynced
check_switch=/root/rsync_switch.txt
cdn_key_file=/root/cdn_id_dsa
rsync_logs=/root/rsync_logfile

function do_rsync {
    if [ ! -s $cdn_key_file ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing cdn_key_file, rsync failed!!' \
            | tee -a $rsync_logs
        exit 1
    fi

    if [ ! -d $ROOT_DIR/Games ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing source dir, rsync failed!!!' | tee -a $rsync_logs
        exit 1
    fi
    
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Updating....!!!' \
        | tee -a $rsync_logs

    if ! rsync -n -e "ssh -i $cdn_key_file" \
        sshacs@perfectworld.upload.akamai.com:68820/cc ; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Error: Rsync test failed!!' | tee -a $rsync_logs
    exit 1
fi

    for game in $( ls -1 $ROOT_DIR/Games/ ); do
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" "Test CDN folder $game" \
            | tee -a $rsync_logs
        
        if ! ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
            ls 68820/cc/$game; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'Folder does not exist, create it.' | tee -a $rsync_logs
            ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                mkdir 68820/cc/$game
        fi

        if ! ls -ld $rsynced_dir/$game; then
            mkdir -v $rsynced_dir/$game | tee -a $rsync_logs
            chown -v rsyncuser:rsyncuser -R $rsynced_dir/$game \
                | tee -a $rsync_logs
        fi

        for game_file in $( ls -1 $ROOT_DIR/Games/$game ); do
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                "Rsync $ROOT_DIR/Games/$game/$game_file start!!" \
                | tee -a $rsync_logs
            rsync -avc --timeout=7200 --progress -e "ssh -i $cdn_key_file" \
                $ROOT_DIR/Games/$game/$game_file \
                sshacs@perfectworld.upload.akamai.com:68820/cc/$game/ \
                | tee -a $rsync_logs
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                "Rsync $ROOT_DIR/Games/$game/$game_file Done!!" \
                | tee -a $rsync_logs
        done

        mv -v $ROOT_DIR/Games/$game/* $rsynced_dir/$game/ | tee -a $rsync_logs

    done

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'update check_switch file' \
        | tee -a $rsync_logs
    rsync -av $rsync_switch $check_switch
}

function notify_ftp{
    notify_file=$(date +%Y-%m-%d-%T)-done
    touch /tmp/$notify_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd COREClient
lcd /tmp
put -a $notify_file
exit
EOF
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
    chown -v rsyncuser:rsyncuser -R $rsynced_dir
fi

if [ ! -e $check_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'No check_switch file, the first time for rsync!!' | tee -a $rsync_logs
    do_rsync
    notify_ftp
    exit 0
fi

if [ $rsync_switch -nt $check_switch ]; then
    do_rsync
    notify_ftp
    exit 0
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Nothing need to update'| tee -a $rsync_logs
    exit 0
fi
