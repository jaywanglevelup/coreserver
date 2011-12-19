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
fs2cdn_pid=/root/fs2cdn_rsync.pid

function error_ftp {
error_file=$(date +%Y-%m-%d-%T)-$2-error
echo "$1" > /tmp/$error_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $error_file
exit
EOF
rm /tmp/$error_file
}

function notify_ftp {
    notify_file=$(date +%Y-%m-%d-%T)-done
    touch /tmp/$notify_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd COREClient
lcd /tmp
put $notify_file
exit
EOF
}

function do_rsync {
    if [ ! -s $cdn_key_file ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing cdn_key_file, rsync failed!!' \
            | tee -a $rsync_logs
        rm $fs2cdn_pid
        error_ftp 'Error: Missing cdn_key_file, rsync failed!!'
        exit 1
    fi

    if [ ! -d $ROOT_DIR/Games ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing source dir, rsync failed!!!' | tee -a $rsync_logs
        rm $fs2cdn_pid
        error_ftp 'Error: Missing source dir, rsync failed!!!'
        exit 1
    fi
    
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Updating....!!!' \
        | tee -a $rsync_logs

    if ! rsync -n -e "ssh -i $cdn_key_file" \
        sshacs@perfectworld.upload.akamai.com:68820/cc ; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Error: Rsync test failed!!' | tee -a $rsync_logs
    rm  $fs2cdn_pid
    error_ftp 'Error: Rsync test failed!!'
    exit 1
    fi

    #if [ -s $ROOT_DIR/Games/updates/coreversion.xml ]; then
    #    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Deleting coreversion.xml!' \
    #        | tee -a $rsync_logs
    #    ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
    #        rm 68820/cc/updates/coreversion.xml | tee -a $rsync_logs
    #fi


    for game in $( ls -1 $ROOT_DIR/Games/ ); do
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" "Test CDN folder $game" \
            | tee -a $rsync_logs
        
        if ! ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
            ls 68820/cc/$game; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'Folder does not exist, create it.' | tee -a $rsync_logs
            ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                mkdir -v 68820/cc/$game | tee -a $rsync_logs
        fi

        if ! ls -ld $rsynced_dir/$game; then
            mkdir -v $rsynced_dir/$game | tee -a $rsync_logs
            chown -v rsyncuser:rsyncuser -R $rsynced_dir/$game \
                | tee -a $rsync_logs
        fi

        for game_file in $( ls -1 $ROOT_DIR/Games/$game ); do
            if ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                ls 68820/cc/$game/$game_file; then
                printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                    "$game_file exists. Remove it first." | tee -a $rsync_logs
                ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                    rm -v 68820/cc/$game/$game_file | tee -a $rsync_logs
                printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                    'After remove the file: \n' | tee -a $rsync_logs
                ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                    ls 68820/cc/$game | tee -a $rsync_logs
            fi

            sleep 30 

            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                "Rsync $ROOT_DIR/Games/$game/$game_file start!!" \
                | tee -a $rsync_logs
            rsync  -avc --timeout=9000 -e "ssh -i $cdn_key_file" \
                $ROOT_DIR/Games/$game/$game_file \
                sshacs@perfectworld.upload.akamai.com:68820/cc/$game/ \
                | tee -a $rsync_logs
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                "Rsync $ROOT_DIR/Games/$game/$game_file Done!!" \
                | tee -a $rsync_logs
            printf "%s %s %s \n" "$(date +%Y-%m-%d\ %T)" "Info: Local MD5SUM: " \
            $(md5sum $ROOT_DIR/Games/$game/$game_file) | tee -a $rsync_logs
            sleep 50
            printf "%s %s %s\n" "$(date +%Y-%m-%d\ %T)" "Info: Remote MD5SUM: " \
            $(ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
                md5sum 68820/cc/$game/$game_file) | tee -a $rsync_logs
        done

        printf "%s %s %s\n" "$(date +%Y-%m-%d\ %T)" "List files in $game dir:" \
            $(ssh -i $cdn_key_file sshacs@perfectworld.upload.akamai.com \
            ls 68820/cc/$game) | tee -a $rsync_logs

        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" "Backup file to $rsynced_dir" \
            | tee -a $rsync_logs
        #mv -v $ROOT_DIR/Games/$game/* $rsynced_dir/$game/ | tee -a $rsync_logs
        rsync -av $ROOT_DIR/Games/$game $rsynced_dir/ | tee -a $rsync_logs
        rm -fv $ROOT_DIR/Games/$game/* | tee -a $rsync_logs

    done

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'update check_switch file' \
        | tee -a $rsync_logs
    rsync -av $rsync_switch $check_switch
}


echo $$ > $fs2cdn_pid
if [ ! -e $rsync_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Error: No rsync_switch file on ftp server. Exit!!' | tee -a $rsync_logs
    rm $fs2cdn_pid
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
    printf "========================================\n" | tee -a $rsync_logs
    do_rsync
    notify_ftp
    rm $fs2cdn_pid
    exit 0
fi

if [ $rsync_switch -nt $check_switch ]; then
    printf "========================================\n" | tee -a $rsync_logs
    do_rsync
    notify_ftp
    rm $fs2cdn_pid
    exit 0
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Nothing need to update'
#        'Info: Nothing need to update'| tee -a $rsync_logs
    rm $fs2cdn_pid
    exit 0
fi
