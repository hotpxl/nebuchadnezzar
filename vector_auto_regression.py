#!/usr/bin/env python3.4
import stats.data
import stats.plot
import stats.preprocess
import pandas
import numpy as np
import matplotlib.pyplot as plt
import matplotlib.dates
import datetime
from statsmodels.tsa.api import VAR, DynamicVAR

sse_indices = stats.data.sse_indices()
for i in sse_indices:
    d = stats.data.get_merged(i, 'date', 'volume', 'readCount')
    # strip first few data points
    d = d[2:]
    for window_size in range(3, 10):
    # window_size = 7
        raw_volume = d[:, 1].astype(float)
        volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size).astype(float)))
        read_count = d[:, 2].astype(float)
        data = pandas.DataFrame({'volume': volume, 'readCount': read_count})
        data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
        model = VAR(data)
        lag = model.select_order()['hqic']
        length = data.values.shape[0]
        print('using lag {}'.format(lag))
        results = model.fit(lag)
        # import IPython; IPython.embed()
        prediction = [0] * (lag)
        for j in range(lag, length):
            prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
        pred = np.asarray(prediction).reshape((length, 1))
        fig, ax = plt.subplots()
        dates = list(map(lambda x: datetime.datetime.strptime(x, '%Y-%m-%d').date(), d[:, 0]))
        ax.plot(dates, pred, 'r', label='forecast')
        ax.plot(dates, volume, 'b', label='real')
        ax.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
        fig.autofmt_xdate()
        ax.set_ylabel('Volume')
        ax.legend()
        plt.show()
        # plt.savefig('{}_{}.png'.format(i, window_size))

# stats.plot.twin_x(np.concatenate((d[:, 1].reshape((length, 1)), pred), axis=1))

# import IPython; IPython.embed()

