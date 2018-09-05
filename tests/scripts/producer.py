#!/usr/bin/env python3


import kafka
import argparse
import signal
from random import choices as random_choice
from string import ascii_letters
from time import sleep


def get_args():
    p = argparse.ArgumentParser()

    p.add_argument('-b', '--brokers', required=True,
        help='CSV list of brokers (IP:port)')
    p.add_argument('-r', '--rate', required=False, type=int, default=1,
        help='Message production rate')
    p.add_argument('-t', '--topic', required=False, default='test',
        help='Target topic name')
    p.add_argument('--random', required=False, default=False, action='store_true',
        help='Enable random character insertion into message')

    mtxg = p.add_mutually_exclusive_group(required=True)
    mtxg.add_argument('-m', '--message',
        help='A test message to send')
    mtxg.add_argument('-f', '--file',
        help='A file containing a test message to send')

    return p.parse_args()


def add_random(msg):
        return msg + ' - ' + ''.join(random_choice(ascii_letters, k=32))


def get_kafka_producer(brokers):
    return kafka.KafkaProducer(bootstrap_servers=brokers)


def message_sender(p, topic, rate, msg, random):
    while True:
        sleep(1/rate)
        if random:
            p.send(topic, add_random(msg).encode('utf-8'))
        else:
            p.send(topic, msg.encode('utf-8'))


def signal_handler(sig, frame):
    producer.close()
    exit()


if __name__ == '__main__':
    try:
        args = get_args()
        producer = get_kafka_producer(args.brokers)
        signal.signal(signal.SIGTERM, signal_handler)
        message_sender(producer, args.topic, args.rate, args.message, args.random)
    except KeyboardInterrupt:
        print('Aborting...')
    finally:
        producer.close()
