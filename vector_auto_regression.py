#!/usr/bin/env python3.4
import stats.data
import stats.plot
import stats.preprocess
import pandas
import numpy as np
import matplotlib.pyplot as plt
from statsmodels.tsa.api import VAR, DynamicVAR

d = stats.data.get_merged(600036, 'date', 'volume', 'readCount')
# strip first few data points
d = d[2:]
data = pandas.DataFrame({'volume': d[:, 1].astype(float), 'readCount': d[:, 2].astype(float)})
data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
model = VAR(data)
lag = model.select_order()['hqic']
length = data.values.shape[0]
print('using lag {}'.format(lag))
results = model.fit(lag)
prediction = [0] * (lag - 1)
for i in range(lag, length + 1):
    prediction.append(results.forecast(data.values[i - lag: i], 1)[0][1])
pred = np.asarray(prediction).reshape((length, 1))
plt.plot(np.arange(length), pred, 'r', np.arange(length), d[:, 1], 'b')
plt.show()
# stats.plot.twin_x(np.concatenate((d[:, 1].reshape((length, 1)), pred), axis=1))

# import IPython; IPython.embed()

