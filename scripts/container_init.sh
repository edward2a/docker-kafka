#!/bin/sh
set -eu

set ZOO_PID
set KFK_PID

NET_IF=${NET_IF:-eth0}
NET_PORT=${NET_PORT:-9092}
ZOO_CONFIG=/opt/kafka/config/zookeeper.properties
KFK_CONFIG=/opt/kafka/config/server.properties

function configure_kafka_ip(){
    local NET_ADDR

    NET_ADDR=$(ip addr show dev ${NET_IF} | pcregrep -o 'inet \K[\d\.]+')
    sed -i -e "s|^host\.name=.*$|host.name=${NET_ADDR}|" ${KFK_CONFIG}
    sed -i -e "s|^advertised\.host\.name=.*$|advertised.host.name=${NET_ADDR}|" ${KFK_CONFIG}
    sed -i -e "s|^listeners=.*$|listeners=PLAINTEXT://${NET_ADDR}:${NET_PORT}|" ${KFK_CONFIG}
    sed -i -e "s|^advertised.listeners=.*$|advertised.listeners=PLAINTEXT://${NET_ADDR}:${NET_PORT}|" ${KFK_CONFIG}
}

function start_kafka(){

    configure_kafka_ip

    /opt/kafka/bin/zookeeper-server-start.sh ${ZOO_CONFIG} &
    ZOO_PID=$!

    sleep 5

    /opt/kafka/bin/kafka-server-start.sh ${KFK_CONFIG} &
    KFK_PID=$!
}

function stop_kafka(){
    kill $KFK_PID
    sleep 5
    kill $ZOO_PID
}

trap stop_kafka SIGTERM SIGINT
start_kafka
wait

