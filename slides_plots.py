#!/usr/bin/env python3.4
import datetime
import math
import matplotlib.pyplot as plt
import matplotlib.dates
import numpy as np
import pandas
import statsmodels.tsa.api
import statsmodels.tsa.stattools
import stats.data

all_plots = []

def register_plot(func):
    def ret(*args, **kwargs):
        kwargs['func_name'] = func.__name__
        return func(*args, **kwargs)
    all_plots.append(ret)
    return ret

@register_plot
def volume_and_click_count(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'volume', 'readCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    volume = d[:, 1]
    click_count = d[:, 2]
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, volume, 'b-', label='Volume')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Volume')
    lines += ax1.plot(dates, click_count, 'r-', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def price_and_click_count(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'close', 'readCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    price = d[:, 1]
    click_count = d[:, 2]
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, price, 'b-', label='Close price')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Close price')
    lines += ax1.plot(dates, click_count, 'r-', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def granger_causality_test_volume_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test', 'r'),
        ('params_ftest', 'Params $F$ test', 'g'),
        ('lrtest', 'LR test', 'b'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test', 'y'),
    ]
    for index in stats.data.sse_indices():
        d = stats.data.get_merged_old(index, 'date', 'volume', 'readCount')
        volume = d[:, 1].astype(float)
        click_count = d[:, 2].astype(float)
        data = pandas.DataFrame({
            'volume': volume,
            'clickCount': click_count})
        data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
        model = statsmodels.tsa.api.VAR(data)
        lag_order = model.select_order(verbose=False)
        lag = lag_order['hqic']
        res = statsmodels.tsa.api.stattools.\
                grangercausalitytests(d[:, 1:], lag, verbose=False)
        cur = []
        for i in tests:
            cur.append(res[lag][0][i[0]][1])
        results.append(cur)
    fig, ax = plt.subplots()
    ax.set_ylim((0, 1))
    index = np.arange(len(results))
    bar_width = 0.2
    for i in range(len(tests)):
        plt.bar(index + i * bar_width, np.asarray(results)[:, i].flatten(), bar_width, color=tests[i][2], label=tests[i][1])
    plt.xlabel('Stock')
    plt.ylabel('$p$ value')
    plt.legend(loc=0)
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def granger_causality_test_price_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test', 'r'),
        ('params_ftest', 'Params $F$ test', 'g'),
        ('lrtest', 'LR test', 'b'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test', 'y'),
    ]
    for index in stats.data.sse_indices():
        d = stats.data.get_merged_old(index, 'date', 'close', 'readCount')
        price = d[:, 1].astype(float)
        click_count = d[:, 2].astype(float)
        data = pandas.DataFrame({
            'price': price,
            'clickCount': click_count})
        data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
        model = statsmodels.tsa.api.VAR(data)
        lag_order = model.select_order(verbose=False)
        lag = lag_order['hqic']
        res = statsmodels.tsa.api.stattools.\
                grangercausalitytests(d[:, 1:], lag, verbose=False)
        cur = []
        for i in tests:
            cur.append(res[lag][0][i[0]][1])
        results.append(cur)
    fig, ax = plt.subplots()
    ax.set_ylim((0, 1))
    index = np.arange(len(results))
    bar_width = 0.2
    for i in range(len(tests)):
        plt.bar(index + i * bar_width, np.asarray(results)[:, i].flatten(), bar_width, color=tests[i][2], label=tests[i][1])
    plt.xlabel('Stock')
    plt.ylabel('$p$ value')
    plt.legend(loc=0)
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def granger_causality_test_price_positive_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test', 'r'),
        ('params_ftest', 'Params $F$ test', 'g'),
        ('lrtest', 'LR test', 'b'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test', 'y'),
    ]
    for index in stats.data.sse_indices():
        d = stats.data.get_merged_old(index, 'date', 'close', 'readCount')
        ds = stats.data.get_merged(index, 'positiveCount', 'negativeCount')
        price = d[:, 1].astype(float)
        click_count = np.multiply(ds[:, 0].astype(float) / (ds[:, 0] + ds[:, 1]).astype(float), d[:, 2].astype(float))
        data = pandas.DataFrame({
            'price': price,
            'clickCount': click_count})
        data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
        model = statsmodels.tsa.api.VAR(data)
        lag_order = model.select_order(verbose=False)
        lag = lag_order['hqic']
        res = statsmodels.tsa.api.stattools.\
                grangercausalitytests(d[:, 1:], lag, verbose=False)
        cur = []
        for i in tests:
            cur.append(res[lag][0][i[0]][1])
        results.append(cur)
    fig, ax = plt.subplots()
    ax.set_ylim((0, 1))
    index = np.arange(len(results))
    bar_width = 0.2
    for i in range(len(tests)):
        plt.bar(index + i * bar_width, np.asarray(results)[:, i].flatten(), bar_width, color=tests[i][2], label=tests[i][1])
    plt.xlabel('Stock')
    plt.ylabel('$p$ value')
    plt.legend(loc=0)
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def volume_forecast_regression_line(func_name):
    d = stats.data.get_merged_old(600036, 'date', 'volume', 'readCount')
    volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    data = pandas.DataFrame({
        'volume': volume,
        'clickCount': click_count
    })
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    lag = model.select_order(verbose=False)['hqic']
    length = data.values.shape[0]
    results = model.fit(ic='hqic')
    prediction = [0] * (lag)
    for j in range(lag, length):
        prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
    cnt = 0
    for j in range(lag, length):
        diff = prediction[j] - volume[j]
        cnt += diff ** 2
    print(math.sqrt(cnt / (length - lag)) / (max(volume) - min(volume)))
    fig, ax = plt.subplots()
    ax.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    ax.plot(dates, volume, 'r-', label='Real')
    ax.plot(dates, prediction, 'b-', label='Prediction')
    ax.set_ylabel('Volume')
    ax.set_xlabel('Date')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

@register_plot
def price_forecast_regression_line(func_name):
    d = stats.data.get_merged_old(600036, 'date', 'close', 'readCount')
    ds = stats.data.get_merged(600036, 'positiveCount', 'negativeCount')
    price = d[:, 1].astype(float)
    click_count = np.multiply(ds[:, 0].astype(float) / (ds[:, 0] + ds[:, 1]).astype(float), d[:, 2].astype(float))
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    data = pandas.DataFrame({
        'price': price,
        'clickCount': click_count
    })
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    lag = model.select_order(verbose=False)['hqic']
    length = data.values.shape[0]
    results = model.fit(ic='hqic')
    prediction = [0] * (lag)
    for j in range(lag, length):
        prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
    cnt = 0
    for j in range(lag, length):
        diff = prediction[j] - price[j]
        cnt += diff ** 2
    print(math.sqrt(cnt / (length - lag)) / (max(price) - min(price)))
    fig, ax = plt.subplots()
    ax.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    dates = dates[lag:]
    prediction = prediction[lag:]
    price = price[lag:]
    ax.plot(dates, price, 'r-', label='Real')
    ax.plot(dates, prediction, 'b-', label='Prediction')
    ax.set_ylabel('Price')
    ax.set_xlabel('Date')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('slides/final/plots/{}.pdf'.format(func_name))

if __name__ == '__main__':
    for i in all_plots:
        i()
