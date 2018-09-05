FROM alpine:3.7

# JMX exporter installation based on:
# https://www.robustperception.io/monitoring-kafka-with-prometheus
# Kafka/JMX config file sourced from:
# https://raw.githubusercontent.com/prometheus/jmx_exporter/ad3b4f97017790fbb0883bc8e8a6733a2c654f15/example_configs/kafka-2_0_0.yml

ARG KAFKA_VERSION=2.0.0
ARG SCALA_VERSION=2.11
ARG JMX_EXP_VERSION=0.10

RUN apk update && \
    apk add openjdk8-jre-base bash pcre-tools

RUN addgroup -S kafka && \
    adduser -S -D -G kafka kafka

RUN wget http://mirrors.whoishostingthis.com/apache/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz && \
    mkdir /opt && \
    tar -xf kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz -C /opt && \
    ln -s /opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION} /opt/kafka && \
    mkdir /opt/kafka/data_kafka /opt/kafka/data_zookeeper

RUN wget -O /opt/kafka/libs/jmx_prometheus_javaagent.jar http://central.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${JMX_EXP_VERSION}/jmx_prometheus_javaagent-${JMX_EXP_VERSION}.jar

ADD config/zookeeper-single_node.properties /opt/kafka/config/zookeeper.properties
ADD config/server-single_node.properties /opt/kafka/config/server.properties
ADD config/kafka_jmx.yml /opt/kafka/config/kafka_jmx.yml
ADD scripts/container_init.sh /opt/kafka/bin/kafka-init.sh

RUN chmod 755 /opt/kafka/bin/kafka-init.sh

ENTRYPOINT /opt/kafka/bin/kafka-init.sh

ENV NET_IF=eth0 \
    NET_PORT=9092 \
    KAFKA_HEAP_OPTS='-Xms384M -Xmx384M' \
    KAFKA_JMX_ENABLE=1 \
    KAFKA_JMX_IF=eth0 \
    KAFKA_JMX_PORT=9045

EXPOSE 9092

LABEL description='Single node kafka + zookeeper with default 384Mb heap' \
      maintainer='edward2a@gmail.com'

VOLUME ["/opt/kafka/data_kafka", "/opt/kafka/data_zookeeper"]
