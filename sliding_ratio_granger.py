#!/usr/bin/env python3.4
import json
from matplotlib.pyplot import *
import numpy as np
from statsmodels.tsa import stattools
import stats

with open('./data/sse_50.json') as f:
    sseIndices = json.load(f)
for sse in sseIndices:
    with open('./tmp/{}.json'.format(sse)) as f:
        data = json.load(f)
    volume = np.asarray([x['volume'] for x in data])
    volume = volume[2:]
    readCount = np.asarray([x['readCount'] for x in data])
    readCount = readCount[2:]
    for windowSize in range(2, 20):
        v = stats.slidingRatio(volume, windowSize)
        v = np.reshape(v, (len(v), 1))
        # r = stats.slidingRatio(readCount, windowSize)
        r = np.asarray(readCount[:len(v)])
        r = np.reshape(r, (len(r), 1))
        d = np.concatenate([v, r], axis=1)
        print(windowSize)
        res = stattools.grangercausalitytests(d, 7, verbose=True)
    break

