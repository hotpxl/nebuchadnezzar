#!/usr/bin/env python2
from __future__ import print_function
import argparse
import time
import json
import logging
import multiprocessing
import os
import redis
import nltk
from sentiment import sentiment_score

# Logger
logger = logging.getLogger(__name__)
logger.setLevel(logging.DEBUG)
ch = logging.StreamHandler()
ch.setLevel(logging.DEBUG)
formatter = logging.Formatter('%(asctime)s %(levelname)s: [%(name)s] %(message)s')
ch.setFormatter(formatter)
logger.addHandler(ch)

def analysis_worker(i):
    source_redis = redis.StrictRedis(db=1, password='whatever')
    target_redis = redis.StrictRedis(db=2, password='whatever')
    key = target_redis.rpop('tasks')
    while key != None:
        text = source_redis.get(key)
        sent = sentiment_score(json.loads(text)['translation'])
        target_redis.set(key, sent)
        logger.info('{} remaining'.format(target_redis.llen('tasks')))
        key = target_redis.rpop('tasks')

if __name__ == '__main__':
    # Parser
    parser = argparse.ArgumentParser(description='analyze sentiment')
    group = parser.add_argument_group(title='required arguments')
    group.add_argument('--processes', type=int, required=True, help='number of parallel processes to run')
    args = parser.parse_args()
    assert(0 < args.processes)
    nltk_path = os.path.join(os.path.dirname(os.path.realpath(__file__)), 'nltk_data')
    nltk.data.path.append(nltk_path)
    p = multiprocessing.Pool(args.processes)
    p.map(analysis_worker, range(args.processes))

