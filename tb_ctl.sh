#!/bin/bash

SAIC_HOME=.
TG=ptf
TARGET=saivs
ASIC_TYPE=trident2

while getopts "hat" OPT; do
    case ${OPT} in
    h)
        echo "Setup testbed: 1) start client docker; 2) start server docker; 3) create links."
        echo "Usage: tb_ctl.sh [-i] COMMAND"
        echo -e "-h\tShow help"
        echo -e "COMMAND\tstart|stop"
        exit 0
        ;;
    a)
        ASIC_TYPE=$OPTARG
        echo "ASIC type: ${ASIC_TYPE}"
        ;;
    t)
        TARGET=$OPTARG
        echo "Target: ${TARGET}"
        ;;
    *)
        echo "Invalid options"
        exit 1
        ;;
    esac
done

COMMAND=${@: -1}
[[ ! ${COMMAND} =~ start|stop ]] && {
    echo "Incorrect COMMAND provided. Allowed: start|stop"
    exit 1
}

start_all_ptf() {
    $SAIC_HOME/run.sh -i client -c start -a $ASIC_TYPE -t $TARGET -r
    $SAIC_HOME/run.sh -i server -c start -a $ASIC_TYPE -t $TARGET -r
    sudo $SAIC_HOME/veth-create-host.sh sc-server-${ASIC_TYPE}-${TARGET}-run sc-client-run
}

stop_all() {
  $SAIC_HOME/run.sh -i server -c stop
  $SAIC_HOME/run.sh -i client -c stop
}

case $COMMAND in
    start)
        start_all_ptf
        ;;
    stop)
        stop_all
        ;;
esac
