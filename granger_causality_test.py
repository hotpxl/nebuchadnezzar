#!/usr/bin/env python3.4
import numpy as np
import statsmodels.tsa.stattools as stattools
import matplotlib.pyplot as plt
import stats.data
import stats.plot
import stats.preprocess

threshold = 0.05

sse_indices = stats.data.sse_indices()
bar_width=0.2
results = []
results_th = []
for index in sse_indices:
    x = stats.data.get_merged(index, 'volume', 'readCount')
    res = stattools.grangercausalitytests(x, 7, verbose=False)
    cur = [
        res[7][0]['ssr_chi2test'][1],
        res[7][0]['params_ftest'][1],
        res[7][0]['lrtest'][1],
        res[7][0]['ssr_ftest'][1],
    ]
    cur_th = [8] * 4
    for i in range(7, 0, -1):
        if res[i][0]['ssr_chi2test'][1] <= threshold:
            cur_th[0] = i
        if res[i][0]['params_ftest'][1] <= threshold:
            cur_th[1] = i
        if res[i][0]['lrtest'][1] <= threshold:
            cur_th[2] = i
        if res[i][0]['ssr_ftest'][1] <= threshold:
            cur_th[3] = i
    results.append(cur)
    results_th.append(cur_th)
fig, ax = plt.subplots()
index = np.arange(len(results))
plt.bar(index, np.asarray(results)[:, 0].flatten(), bar_width, color='b', label='ssr_chi2test')
plt.bar(index + bar_width, np.asarray(results)[:, 1].flatten(), bar_width, color='y', label='params_ftest')
plt.bar(index + 2 * bar_width, np.asarray(results)[:, 2].flatten(), bar_width, color='r', label='lrtest')
plt.bar(index + 3 * bar_width, np.asarray(results)[:, 3].flatten(), bar_width, color='g', label='ssr_ftest')
plt.xlabel('Stock')
plt.ylabel('Test')
plt.legend(loc=9)
plt.show()
