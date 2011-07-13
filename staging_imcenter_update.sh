#!/bin/bash - 
#===============================================================================
#
#          FILE:  portcheck.sh
# 
#         USAGE:  ./staging_update.sh 
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

#function serv2update {
#    case $1 in
#        corecenter ) echo "update $1"
#            check_binary $todo
#            ;;
#        loginmgr ) echo "update $1"
#            ;;
#        front ) echo "update $1"
#            ;;
#        session ) echo "update $1"
#            ;;
#        imcenter ) echo "update $1"
#            ;;
#    esac
#}
#

function error_ftp {
error_file=$(date +%Y-%m-%d-%T)-$2-error
echo "$1" > /tmp/$error_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $error_file
exit
EOF
}

function notify_ftp {
notify_file=$(date +%Y-%m-%d-%T)-$1-done
touch /tmp/$notify_file
lftp -u shftp,shperfectworld 172.29.31.4 <<EOF
cd Staging
lcd /tmp
put -a $notify_file
exit
EOF
}

# update serv: corecenter loginmgr session front imcenter
serv='imcenter'
#if [ $serv = 'front' ]; then
#    bin_dir=/usr/local/bin/$serv
#elif [ $serv = 'session' ]; then
#    bin_dir=$(for i in $(seq 8); do echo -n session"$i " ; done)
#else
#    bin_dir=/usr/local/bin
#fi

bin_dir=/usr/local/bin
source_dir=/home/rsyncuser/$serv/$serv
binbackup_dir=/home/rsyncuser/binbackup
updated_dir=/home/rsyncuser/updated
check_switch=/home/rsyncuser/$serv/staging_rsync_switch.txt
update_logs=/root/staging_update_logfile


if [ ! -e $check_switch ]; then
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Nothing need to update'
        #'Info: Nothing need to update' | tee -a $update_logs
else
    printf "========================================\n" | tee -a $update_logs
    if [ ! -d $binbackup_dir ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'INFO: No binbackup dir, create it.' | tee -a $update_logs
        mkdir -v $binbackup_dir | tee -a $update_logs
        chown rsyncuser:rsyncuser -v -R $binbackup_dir | tee -a $update_logs
    fi

    if [ ! -d $updated_dir ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'INFO: No updated dir dir, create it.' | tee -a $update_logs
        mkdir -v $updated_dir | tee -a $update_logs
        chown rsyncuser:rsyncuser -v -R $updated_dir | tee -a $update_logs
    fi
    
    if ! ls $source_dir/$serv*.zip; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            "Error: No $serv zip file" | tee -a $update_logs
        error_ftp "Error: No $serv zip file" $serv
        rm -f $source_dir/*
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Info: Remove check_switch file!' | tee -a $update_logs
        rm -v $check_switch | tee -a $update_logs
        exit 1
    fi

    cd $source_dir
    if ! unzip $serv*.zip; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Error: Not a zip file! Wrong file type!' | tee -a $update_logs
        error_ftp 'Error: Not a zip file! Wrong file type!!' $serv
        rm -f $source_dir/*
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Info: Remove check_switch file!' | tee -a $update_logs
        rm -v $check_switch | tee -a $update_logs
        exit 1
    fi
    
    if [ "$serv" -ot "$bin_dir/$serv" ]; then
        printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
            'Warning: Running binary is newer than source binary!' \
            | tee -a $update_logs
    fi
    
    printf "%s %s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: New binary md5sum: ' $(md5sum $serv) \
        | tee -a $update_logs

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Backup source file!' | tee -a $update_logs
    mv -v $serv*.zip $updated_dir/$serv$(date +%Y-%m-%d-%T).zip \
        | tee -a $update_logs
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Backup old binary!' | tee -a $update_logs
    cp -v $bin_dir/$serv $binbackup_dir/$serv$(date +%Y-%m-%d-%T) \
        | tee -a $update_logs
    chmod -v a+x $serv | tee -a $update_logs | tee -a $update_logs

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Kill old process!' | tee -a $update_logs
    
    #if ! $(pgrep supervisord); then
    #    printf "%s \n" 'Error: Start Supervisord daemon failed'
    #fi
    
    pkill -f $bin_dir/$serv
    sleep 2
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        "Info: Replace $serv binary!" | tee -a $update_logs
    cp -v -p $serv $bin_dir/ | tee -a $update_logs

    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Start new process!' | tee -a $update_logs
    $bin_dir/$serv $bin_dir/$serv.xml 1> /dev/null 2>&1 &
    rm -f $source_dir/*
    printf "%s %s \n" "$(date +%Y-%m-%d\ %T)" \
        'Info: Remove check_switch file!' | tee -a $update_logs
    rm -v $check_switch | tee -a $update_logs
    notify_ftp $serv
    exit 0
fi
