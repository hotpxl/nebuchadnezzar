#!/usr/bin/env python3.4
import json
import numpy as np
import statsmodels.tsa.stattools as stattools
import stats.data
import stats.plot
import stats.preprocess

threshold = 0.05

sse_indices = stats.data.sse_indices()
for index in sse_indices:
    data = stats.data.get_merged(index, 'volume', 'readCount')
    res = stattools.grangercausalitytests(x, 7, verbose=False)
    bestResults = []
    for i in res:
        good = 0
        for j in res[i][0]:
            if res[i][0][j][1] <= threshold:
                good += 1
        bestResults.append((i, good))
    bestResults.sort(key=lambda x: -x[1])
    print(sse, bestResults[0])

