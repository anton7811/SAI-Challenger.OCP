#! /bin/bash

SERVER=$1
CLIENT=$2

if [ -z $SERVER ]; then
    echo "Server NetNS must be specified."
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
