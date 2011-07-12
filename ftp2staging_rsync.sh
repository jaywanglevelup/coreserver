#!/bin/bash - 
#===============================================================================
#
#          FILE:  cdn_rsync.sh
# 
#         USAGE:  ./ft2staging.sh 
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Jay Wang (), 
#       COMPANY: PWRD
#       CREATED: 07/11/2011 03:49:38 PM CST
#      REVISION:  ---
#===============================================================================

# rsync from management to cc-staging-xxxx
# Put this file on cc-management server (ftp). 
# It will auto run rsync to cc-staging-corecenter server, if there is any
# update
# 

ROOT_DIR=/home/shftp/Staging
# rsync will start in 5 minutes after update this file
rsync_switch=$ROOT_DIR/staging_rsync_switch.txt
rsynced_dir=$ROOT_DIR/rsynced
check_switch=/root/staging_rsync_switch.txt
rsync_passwd=/root/rsync_passwd
rsync_logs=/root/staging_rsync_logfile


function error_ftp {
error_file=$(date +%Y-%m-%d-%T)-error
echo "$1" > /tmp/$error_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $error_file
exit
EOF
}

function notify_ftp {
notify_file=$(date +%Y-%m-%d-%T)-done
touch /tmp/$notify_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $notify_file
exit
EOF
}

function do_rsync {
    if [ ! -s $rsync_passwd ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing or no password, rsync failed!!'| tee -a $rsync_logs
        exit 1
    fi

    for app in corecenter front imcenter loginmgr session; do
        if [ ! -d $ROOT_DIR/$app ]; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'Error: Missing source dir, rsync failed!!!' | tee -a $rsync_logs
            exit 1
        fi

        if [ 0 -eq $(ls $ROOT_DIR/$app/ | wc -l ) ]; then
            echo "$app nothing to update"

        elif [ 1 -eq $(ls $ROOT_DIR/$app/ | wc -l ) ]; then
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" 'Updating....!!!'\
                | tee -a $rsync_logs

            case $app in
                corecenter )
                    rsync_addresses=('172.29.31.18')
                    ;;
                front )
                    rsync_addresses=('172.29.31.20')
                    ;;
                imcenter )
                    rsync_addresses=('172.29.31.21')
                    ;;
                loginmgr )
                    rsync_addresses=('172.29.31.19')
                    #rsync_addresses=('172.29.31.19' '172.29.31.16')
                    ;;
                session )
                    rsync_addresses=('172.29.31.20')
                    ;;
            esac

            for host_address in "${rsync_addresses[@]}"; do
                if ! rsync -n rsyncuser@$host_address::$app \
                    --password-file $rsync_passwd ; then
                    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                        "Error: Rsync $app $host_address test failed!!"\
                        | tee -a $rsync_logs
                    exit 1
                fi

                printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                    "Rsync $ROOT_DIR/$app $host_address start!!" \
                    | tee -a $rsync_logs

                rsync -avc $ROOT_DIR/$app rsyncuser@$host_address::$app \
                    --password-file $rsync_passwd | tee -a $rsync_logs

                rsync -avc $rsync_switch rsyncuser@$host_address::$app \
                    --password-file $rsync_passwd | tee -a $rsync_logs

                printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                    "Rsync $ROOT_DIR/$app $host_address Done!!" \
                    | tee -a $rsync_logs
                
            done

            mv -v $ROOT_DIR/$app/* $rsynced_dir/

        else
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'Error: More than 1 file update, rsync failed!!' \
                | tee -a $rsync_logs
            error_ftp "$app more than 1 file update"
            exit 1
        fi

    done

    printf "%s %s \n" 'update check_switch file' | tee -a $rsync_logs
    rsync -av $rsync_switch $check_switch
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
