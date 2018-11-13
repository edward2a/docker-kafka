#!/bin/bash
set -eu

set ZOO_PID
set KFK_PID
set KAFKA_JMX_OPTS

PUBLIC_IF=${PUBLIC_IF:-eth0}
PUBLIC_PORT=${PUBLIC_PORT:-9092}
REPLICATION_IF=${REPLICATION_IF:-9092}
REPLICATION_PORT=${REPLICATION_PORT:-9093}
ZOO_CONFIG=/opt/kafka/config/zookeeper.properties
if [ ${CLUSTER_NODE} == 1 ]; then
    KFK_CONFIG=/opt/kafka/config/server-cluster.properties
else
    KFK_CONFIG=/opt/kafka/config/server-single.properties
fi

KAFKA_JMX_ENABLE=${KAFKA_JMX_ENABLE:-1}
# TODO: use JMX_IF
KAFKA_JMX_IF=${JMX_IF:-eth0}
KAFKA_JMX_PORT=${KAFKA_JMX_PORT:-9045}
KAFKA_JMX_CONFIG=/opt/kafka/config/kafka_jmx.yml

function get_if_ip() {
    if [[ ${1} == eth[0-9] ]]; then
        ip addr show dev ${1} | pcregrep -oi 'inet \K[\d\.]+'
    else
        echo "ERROR: Missing or wrong interface name: ${1}"
        return 1
    fi
}

function configure_kafka_single(){
    local NET_ADDR

    NET_ADDR=$(get_if_ip ${PUBLIC_IF})
    sed -i -e "s|^host\.name=.*$|host.name=${NET_ADDR}|" ${KFK_CONFIG}
    sed -i -e "s|^advertised\.host\.name=.*$|advertised.host.name=${NET_ADDR}|" ${KFK_CONFIG}
    sed -i -e "s|^listeners=.*$|listeners=PLAINTEXT://${NET_ADDR}:${PUBLIC_PORT}|" ${KFK_CONFIG}
    sed -i -e "s|^advertised.listeners=.*$|advertised.listeners=PLAINTEXT://${NET_ADDR}:${PUBLIC_PORT}|" ${KFK_CONFIG}

    # TODO: could this be an address different than kafka?
    if [ ${KAFKA_JMX_ENABLE} == 1 ]; then
        KAFKA_JMX_OPTS="-javaagent:/opt/kafka/libs/jmx_prometheus_javaagent.jar=${NET_ADDR}:${KAFKA_JMX_PORT}:/opt/kafka/config/kafka_jmx.yml"
    fi
}

function configure_kafka_cluster(){
    local PUBLIC_IP
    local REPLICATION_IP

    PUBLIC_IP=$(get_if_ip ${PUBLIC_IF})
    REPLICATION_IP=$(get_if_ip ${REPLICATION_IF})

    for token in PUBLIC_IP PUBLIC_PORT REPLICATION_IP REPLICATION_PORT ZK_CLUSTER BROKER_ID; do
        sed -i -e "s/%@${token}@%/${!token}/g" ${KFK_CONFIG}
    done

    if [ ${KAFKA_JMX_ENABLE} == 1 ]; then
        KAFKA_JMX_OPTS="-javaagent:/opt/kafka/libs/jmx_prometheus_javaagent.jar=${PUBLIC_IP}:${KAFKA_JMX_PORT}:/opt/kafka/config/kafka_jmx.yml"
    fi
}


function start_kafka(){

    # Start single node
    if [ ${CLUSTER_NODE} == 0 ]; then
        configure_kafka_single

        /opt/kafka/bin/zookeeper-server-start.sh ${ZOO_CONFIG} &
        ZOO_PID=$!

        sleep 5

    # Start cluster node
    elif [ ${CLUSTER_NODE} == 1 ]; then
        configure_kafka_cluster
    fi

    # Enable JMX?
    if [ ${KAFKA_JMX_ENABLE} == 1 ]; then
        export KAFKA_OPTS="${KAFKA_JMX_OPTS}"
    fi

    /opt/kafka/bin/kafka-server-start.sh ${KFK_CONFIG} &
    KFK_PID=$!
}

function stop_kafka(){
    kill $KFK_PID
    if [ ${CLUSTER_NODE} == 0 ]; then
        sleep 5
        kill $ZOO_PID
    fi
}

trap stop_kafka SIGTERM SIGINT
start_kafka
wait

