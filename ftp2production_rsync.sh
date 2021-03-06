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

ROOT_DIR=/home/shftp/Production
# rsync will start in 5 minutes after update this file
rsync_switch=$ROOT_DIR/production_rsync_switch.txt
rsynced_dir=$ROOT_DIR/rsynced
check_switch=/root/production_rsync_switch.txt
rsync_passwd=/root/rsync_passwd
rsync_logs=/root/production_rsync_logfile



function do_rsync {
    if [ ! -s $rsync_passwd ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Missing or no password, rsync failed!!'| tee -a $rsync_logs
        exit 1
    fi

    for app in corecenter front imcenter loginmgr session all; do
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
                    rsync_addresses=('172.29.30.7') #cc-corecenter
                    ;;
                front )
                    rsync_addresses=('172.29.30.9') #cc-c2s
                    ;;
                imcenter )
                    rsync_addresses=('172.29.30.15') #cc-sm2
                    ;;
                loginmgr )
                    rsync_addresses=('172.29.30.8')  #cc-loginmgr
                    ;;
                session )
                    rsync_addresses=('172.29.30.10') #cc-sm1
                    ;;
                all )
                    rsync_addresses=('172.29.30.7' '172.29.30.9' '172.29.30.15' '172.29.30.8' '172.29.30.10')
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
            appname=$(ls $ROOT_DIR/$app/)
            mv -v $ROOT_DIR/$app/$appname $rsynced_dir/$(date +%Y-%m-%d-%T)$appname

        else
            printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
                'Error: More than 1 file update, rsync failed!!' \
                | tee -a $rsync_logs
            error_ftp "Rsync error: $app more than 1 file update"
            exit 1
        fi

    done

    printf "%s %s \n" 'update check_switch file' | tee -a $rsync_logs
    rsync -av $rsync_switch $check_switch
}

function notify_ftp {
notify_file=$(date +%Y-%m-%d-%T)-rsync-done
touch /tmp/$notify_file
lftp -u aaa,bbb 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $notify_file
exit
EOF
}

function error_ftp {
error_file=$(date +%Y-%m-%d-%T)-rsync-error
echo "$1" > /tmp/$error_file
lftp -u aaa,bbb 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $error_file
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
    chown -v shftp:shftp -R $rsynced_dir
fi


if [ ! -e $check_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'No check_switch file, the first time for rsync!!' | tee -a $rsync_logs
    printf "========================================\n" | tee -a $rsync_logs
    do_rsync
    notify_ftp 
    exit 0
fi

if [ $rsync_switch -nt $check_switch ]; then
    printf "========================================\n" | tee -a $rsync_logs
    do_rsync
    notify_ftp 
    exit 0
else
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Nothing need to update' 
        #'Info: Nothing need to update' | tee -a $rsync_logs
    exit 0
fi
