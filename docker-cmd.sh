#!/usr/bin/env bash


COMMAND_LINE_OPTIONS_HELP='
Command line options:
    -s/--start          Launch clamav
    -h/--help           Print this help menu

'

print_help() {
    echo $COMMAND_LINE_OPTIONS_HELP
}

getopt --test > /dev/null
if [[ $? -ne 4 ]]; then
    echo "I’m sorry, `getopt --test` failed in this environment."
    exit 1
fi

OPTIONS=sh
LONGOPTIONS=start,help

# -temporarily store output to be able to check for errors
# -e.g. use “--options” parameter by name to activate quoting/enhanced mode
# -pass arguments only via   -- "$@"   to separate them correctly
PARSED=$(getopt --options=$OPTIONS --longoptions=$LONGOPTIONS --name "$0" -- "$@")
if [[ $? -ne 0 ]]; then
    # e.g. $? == 1
    #  then getopt has complained about wrong arguments to stdout
    exit 2
fi
# read getopt’s output this way to handle the quoting right:
eval set -- "$PARSED"

# now enjoy the options in order and nicely split until we see --
while true; do
    case "$1" in
        -s|--start)
            start_spamd="true"
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        --)
            shift
            break
            ;;
        *)
            echo "Programming error"
            exit 3
            ;;
    esac
done

clamav_lib_dir=/var/lib/clamav
clamav_db_dir=/usr/share/clamav/database

if [ ! -f "$clamav_lib_dir/main.cvd" ]; then
    echo "main.cvd not found, copy default one"
    cp $clamav_db_dir/main.cvd $clamav_lib_dir/main.cvd
fi

if [ ! -f "$clamav_lib_dir/daily.cvd" ]; then
    echo "daily.cvd not found, copy default one"
    cp $clamav_db_dir/daily.cvd $clamav_lib_dir/daily.cvd
fi

if [ ! -f "$clamav_lib_dir/bytecode.cvd" ]; then
    echo "bytecode.cvd not found, copy default one"
    cp $clamav_db_dir/bytecode.cvd $clamav_lib_dir/bytecode.cvd
fi

echo "Force permission clamav lib dir"
chown clamav:clamav $clamav_lib_dir/*.cvd

if [ -n "$FRESHCLAM_ENABLE_DEBUG" ]; then
    freshclam_debug_arg="-v"
fi

if [ -n "$CLAMAV_ENABLE_DEBUG" ]; then
    echo "Enable clamv debug mode"
    sed -i 's/^\#\?Debug .*$/Debug yes/g' /etc/clamav/clamd.conf
else
    sed -i 's/^\#\?Debug .*$/\#Debug yes/g' /etc/clamav/clamd.conf
fi

echo "Start freshclam Daemon"
/usr/bin/freshclam --stdout --user=clamav --datadir=/var/lib/clamav $freshclam_debug_arg &

echo "Start ClamAV Daemon"
exec /usr/sbin/clamd --foreground=true

