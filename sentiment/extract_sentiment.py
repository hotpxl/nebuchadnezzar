#!/usr/bin/env python2
from __future__ import print_function
import logging
import argparse
import redis

# Logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s %(levelname)s: [%(name)s] %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

def load_symbol_keys(symbol):
    symbol_redis = redis.StrictRedis(password='whatever')
    if symbol != '*':
        prefix = '{}:*'.format(symbol)
        keys = symbol_redis.keys(prefix)
    else:
        keys = list(filter(lambda x: x != 'progress', symbol_redis.keys('*')))
    logger.info('{} keys'.format(len(keys)))
    return list(map(lambda x: re.search('\d+$', x).group(), keys))

def extract(keys):
    ret = []
    source_redis = redis.StrictRedis(db=2, password='whatever')
    for key in keys:
        ret.append({
            'sent': source_redis.get(key),
            'key': key
        })
    return ret

if __name__ == '__main__':
    # Parser
    parser = argparse.ArgumentParser(description='extract sentiment data')
    group = parser.add_argument_group(title='required arguments')
    group.add_argument('--symbol', required=True, help='symbol to process')
    args = parser.parse_args()
    print(extract(load_symbol_keys(args.symbol)))

