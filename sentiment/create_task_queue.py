#!/usr/bin/env python2
from __future__ import print_function
import logging
import argparse
import redis

def load_symbol_keys(symbol):
    symbol_redis = redis.StrictRedis(password='whatever')
    prefix = '{}:*'.format(symbol)
    keys = symbol_redis.keys(prefix)
    logger.info('{} keys'.format(len(keys)))
    return list(map(lambda x: x[len(prefix):], keys))

def push_task_queue(keys):
    target_redis = redis.StrictRedis(db=2, password='whatever')
    target_redis.delete('tasks')
    target_redis.rpush('tasks', *keys)

if __name__ == '__main__':
    # Logger
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.DEBUG)
    ch = logging.StreamHandler()
    ch.setLevel(logging.DEBUG)
    formatter = logging.Formatter('%(asctime)s %(levelname)s: [%(name)s] %(message)s')
    ch.setFormatter(formatter)
    logger.addHandler(ch)
    # Parser
    parser = argparse.ArgumentParser(description='create task queue for sentiment analysis')
    group = parser.add_argument_group(title='required arguments')
    group.add_argument('--symbol', required=True, help='symbol to process')
    args = parser.parse_args()
    push_task_queue(load_symbol_keys(args.symbol))

