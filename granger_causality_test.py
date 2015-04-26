#!/usr/bin/env python3.4
import json
import numpy as np
import statsmodels.tsa.stattools as stattools

threshold = 0.05

# if __name__ == '__main__':
with open('../data/sse_50.json') as f:
    sseIndices = json.load(f)
for sse in sseIndices:
    with open('./{}.json'.format(sse)) as f:
        data = json.load(f)
    x = [[i['volume'], i['readCount']] for i in data]
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

