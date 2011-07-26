#!/bin/bash - 
#===============================================================================
#
#          FILE:  uploadftp.sh
# 
#         USAGE:  ./uploadftp.sh filename
# 
#   DESCRIPTION:  
# 
#       OPTIONS:  ---
#  REQUIREMENTS:  ---
#          BUGS:  ---
#         NOTES:  ---
#        AUTHOR: Jay Wang (), 
#       COMPANY: PWRD
#       CREATED: 07/15/2011 10:09:58 AM CST
#      REVISION:  ---
#===============================================================================

usage() {
cat << EOF_USAGE
uploadftp.sh server[opt: date].zip
For example:
uploadftp.sh front20110707.zip
EOF_USAGE
exit 1
}

package=${1:? $(usage)}

if [ ! -s $package ]; then
    echo "No $package file!!!"
    exit 1
fi

filetype=${package#*.}

if [ $filetype != zip ]; then
    echo 'Not a zip file!!!'
    exit 1
fi

servername=${package%%[0-9.]*}

case $servername in
    corecenter ) echo "upload $servername"
        ;;
    loginmgr ) echo "upload $servername"
        ;;
    imcenter ) echo "upload $servername"
        ;;
    front ) echo "upload $servername"
        ;;
    session ) echo "upload $servername"
        ;;
    *) 
        echo "Not one of corecenter loginmgr imcenter front session"
        exit 1 
        ;;
esac

touch /tmp/staging_rsync_switch.txt
lftp -u user,pass aaa:bbb:ccc:ddd <<EOF
ls
cd /Staging/$servername/
put  $package
lcd /tmp/
cd /Staging/
put  staging_rsync_switch.txt
exit
EOF
