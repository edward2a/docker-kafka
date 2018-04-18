FROM alpine:3.7

RUN apk update && \
    apk add openjdk8-jre-base bash pcre-tools

RUN addgroup -S kafka && \
    adduser -S -D -G kafka kafka

RUN wget http://mirrors.whoishostingthis.com/apache/kafka/1.1.0/kafka_2.11-1.1.0.tgz && \
    mkdir /opt && \
    tar -xf kafka_2.11-1.1.0.tgz -C /opt && \
    ln -s /opt/kafka_2.11-1.1.0 /opt/kafka && \
    mkdir /opt/kafka/data_kafka /opt/kafka/data_zookeeper

ADD config/zookeeper-single_node.properties /opt/kafka/config/zookeeper.properties
ADD config/server-single_node.properties /opt/kafka/config/server.properties
ADD scripts/container_init.sh /opt/kafka/bin/kafka-init.sh

RUN chmod 755 /opt/kafka/bin/kafka-init.sh

ENTRYPOINT /opt/kafka/bin/kafka-init.sh

ENV NET_IF=eth0 \
    NET_PORT=9092 \
    KAFKA_HEAP_OPTS='-Xms384M -Xmx384M'

EXPOSE 9092

LABEL description='Single node kafka + zookeeper with default 384Mb heap' \
      maintainer='edward2a@gmail.com'
