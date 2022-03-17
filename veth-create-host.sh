#! /bin/bash

# The script creates veth pairs to connect client and server dockers.
# The server docker must use separate netns (which is the default docker behavior).
# The client docker can use separate or host netns. The last option is useful when
# you run SAI-Challenger client with HW DUT or the external test equipment that
# requires network connectivity. In that case you need just skip the second argument of the script
# Usage: ./veth-create-host.sh SERVER_NAME [CLIENT_NAME]

SERVER=$1
CLIENT=$2

if [ -z $SERVER ]; then
    echo "Server Docker name must be specified."
    exit 1
fi

PID=$(docker inspect --format '{{ .State.Pid }}' $SERVER)
SERVER_NETNS="$SERVER_$PID"
ln -s /proc/$PID/ns/net /var/run/netns/$SERVER_NETNS

if [ ! -z $CLIENT ]; then
    PID=$(docker inspect --format '{{ .State.Pid }}' $CLIENT)
    CLIENT_NETNS="$CLIENT_$PID"
    ln -s /proc/$PID/ns/net /var/run/netns/$CLIENT_NETNS
fi

for num in {1..32}; do
    ip link add veth"$num" type veth peer name eth"$num" netns $SERVER_NETNS
    ip netns exec $SERVER_NETNS ip link set eth"$num" up
    ip link set veth"$num" up
    if [ ! -z $CLIENT ]; then
        ip link set dev veth"$num" netns $CLIENT_NETNS
        ip netns exec $CLIENT_NETNS ip link set veth"$num" up
    fi
done
