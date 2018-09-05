#!/usr/bin/env python3


import argparse
import kafka
import signal
from datetime import datetime
from time import sleep


def count_info(signal, frame):
    print('messages collected: ' + str(x))


def get_args():
    p = argparse.ArgumentParser()

    p.add_argument('-b', '--brokers', required=True,
        help='CSV list of brokers (IP:port)')
    p.add_argument('-r', '--rate', required=False, default=1, type=int,
        help='Message consumption rate per second')
    p.add_argument('-t', '--topic', required=False, default='test',
        help='Target topic name')

    return p.parse_args()


def get_kafka_consumer(brokers, topic):
    return kafka.KafkaConsumer(topic, bootstrap_servers=brokers)


def message_consumer(c, rate):
    global x
    while True:
        print(datetime.utcnow(), next(c).value.decode())
        x += 1
        sleep(1/rate)


if __name__ == '__main__':
    args = get_args()
    try:
        x = 0
        signal.signal(signal.SIGPOLL, count_info)
        consumer = get_kafka_consumer(args.brokers, args.topic)
        message_consumer(consumer, args.rate)
    except KeyboardInterrupt:
        print('Aborting...')
    finally:
        consumer.close()
