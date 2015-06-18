#!/usr/bin/env python3.4
import sys
import io
import math
import stats.data
import stats.plot
import stats.preprocess
import datetime
import matplotlib.pyplot as plt
import matplotlib.dates
import pandas
import statsmodels.tsa.api
import statsmodels.tsa.stattools
import numpy as np

all_plots = []

def register_plot(func):
    def ret(*args, **kwargs):
        kwargs['func_name'] = func.__name__
        return func(*args, **kwargs)
    all_plots.append(ret)
    return ret

class Capturing(list):
    def __enter__(self):
        self._stdout = sys.stdout
        sys.stdout = self._stringio = io.StringIO()
        return self

    def __exit__(self, *args):
        self.extend(self._stringio.getvalue().splitlines())
        sys.stdout = self._stdout

@register_plot
def auto_regression_0(func_name):
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    d = stats.data.get_merged('600000', 'date', 'volume', 'clickCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    volume = d[:, 1]
    click_count = d[:, 2]
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, volume, 'k-', label='Volume')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Volume')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def auto_regression_1(func_name):
    d = stats.data.get_merged('600000', 'date', 'volume', 'clickCount')
    volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    data = pandas.DataFrame({'volume': volume,
        'clickCount': click_count})
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    with Capturing() as output:
        model.select_order()
    print('\n'.join(output))

@register_plot
def granger_causality_test_0(func_name):
    d = stats.data.get_merged_old('600000', 'volume', 'readCount')
    with Capturing() as output:
        statsmodels.tsa.api.stattools.\
                grangercausalitytests(d, 5, verbose=True)
    print('\n'.join(output))

@register_plot
def granger_causality_test_1(func_name):
    d = stats.data.get_merged_old('600000', 'volume', 'readCount')
    max_lag = 5
    res = statsmodels.tsa.api.stattools.\
            grangercausalitytests(d, max_lag, verbose=False)
    ssr_chi2test = []
    params_ftest = []
    lrtest = []
    ssr_ftest = []
    for i in range(1, max_lag + 1):
        ssr_chi2test.append(res[i][0]['ssr_chi2test'][1])
        params_ftest.append(res[i][0]['params_ftest'][1])
        lrtest.append(res[i][0]['lrtest'][1])
        ssr_ftest.append(res[i][0]['ssr_ftest'][1])
    x_axis = range(1, max_lag + 1)
    fig, ax = plt.subplots()
    ax.plot(x_axis, ssr_chi2test, 'k-', label='SSR $\chi^{2}$ test')
    ax.plot(x_axis, params_ftest, 'k--', label='Params $F$ test')
    ax.plot(x_axis, lrtest, 'k:', label='LR $\chi^{2}$ test')
    ax.plot(x_axis, ssr_ftest, 'k-.', label='SSR $F$ test')
    ax.set_ylabel('$p$ value')
    ax.set_xlabel('Lag value')
    ax.set_xticks(x_axis)
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def granger_causality_test_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test'),
        ('params_ftest', 'Params $F$ test'),
        ('lrtest', 'LR test'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test'),
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
    index = np.arange(len(results))
    bar_width = 0.8
    for i in range(len(tests)):
        plt.bar(index, np.asarray(results)[:, i].flatten(), bar_width, color='w', label=tests[i][1])
        plt.xlabel('Stock')
        plt.ylabel('$p$ value')
        plt.legend(loc=0)
        plt.savefig('thesis/plots/{}_{}.pdf'.format(func_name, tests[i][0]))
        plt.clf()

@register_plot
def granger_causality_test_on_sse_50_abnormal_lag_selection(func_name):
    d = stats.data.get_merged_old('600028', 'date', 'volume', 'readCount')
    volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    data = pandas.DataFrame({'volume': volume,
        'clickCount': click_count})
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    with Capturing() as output:
        model.select_order()
    print('\n'.join(output))

@register_plot
def granger_causality_test_on_sse_50_abnormal_granger(func_name):
    d = stats.data.get_merged_old('600028', 'volume', 'readCount')
    max_lag = 10
    res = statsmodels.tsa.api.stattools.\
            grangercausalitytests(d, max_lag, verbose=False)
    ssr_chi2test = []
    params_ftest = []
    lrtest = []
    ssr_ftest = []
    for i in range(1, max_lag + 1):
        ssr_chi2test.append(res[i][0]['ssr_chi2test'][1])
        params_ftest.append(res[i][0]['params_ftest'][1])
        lrtest.append(res[i][0]['lrtest'][1])
        ssr_ftest.append(res[i][0]['ssr_ftest'][1])
    x_axis = range(1, max_lag + 1)
    fig, ax = plt.subplots()
    ax.plot(x_axis, ssr_chi2test, 'k-', label='SSR $\chi^{2}$ test')
    ax.plot(x_axis, params_ftest, 'k--', label='Params $F$ test')
    ax.plot(x_axis, lrtest, 'k:', label='LR $\chi^{2}$ test')
    ax.plot(x_axis, ssr_ftest, 'k-.', label='SSR $F$ test')
    ax.set_ylabel('$p$ value')
    ax.set_xlabel('Lag value')
    ax.set_xticks(x_axis)
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def granger_causality_test_on_sse_50_abnormal_plot(func_name):
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    d = stats.data.get_merged_old('600028', 'date', 'volume', 'readCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    volume = d[:, 1]
    click_count = d[:, 2]
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, volume, 'k-', label='Volume')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Volume')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def var_forecast_history_line(func_name):
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    d = stats.data.get_merged_old('600036', 'date', 'volume', 'readCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    volume = d[:, 1]
    click_count = d[:, 2]
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, volume, 'k-', label='Volume')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Volume')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def var_forecast(func_name):
    d = stats.data.get_merged_old(600036, 'date', 'volume', 'readCount')
    volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    data = pandas.DataFrame({
        'volume': volume,
        'clickCount': click_count
    })
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    results = model.fit(ic='hqic')
    print(results.summary())

@register_plot
def var_forecast_regression_line(func_name):
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
    ax.plot(dates, volume, 'k-', label='Real')
    ax.plot(dates, prediction, 'k--', label='Prediction')
    ax.set_ylabel('Volume')
    ax.set_xlabel('Date')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def var_forecast_regression_line_5_step(func_name):
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
    for j in range(lag, length, 5):
        prediction.extend(
            map(lambda x: x[1],
                results.forecast(data.values[j - lag: j], 5)))
    prediction = prediction[:length]
    cnt = 0
    for j in range(lag, length):
        diff = prediction[j] - volume[j]
        cnt += diff ** 2
    print(math.sqrt(cnt / (length - lag)) / (max(volume) - min(volume)))
    fig, ax = plt.subplots()
    ax.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    ax.plot(dates, volume, 'k-', label='Real')
    ax.plot(dates, prediction, 'k--', label='Prediction')
    ax.set_ylabel('Volume')
    ax.set_xlabel('Date')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def sliding_ratio_line(func_name):
    d = stats.data.get_merged_old(600036, 'date', 'volume', 'readCount')
    window_size = 7
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    raw_volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size)))
    click_count = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(click_count, window_size)))
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    lines = []
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, volume, 'k-', label='Volume ratio')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Volume')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count ratio')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def sliding_ratio_forecast(func_name):
    d = stats.data.get_merged_old(600036, 'date', 'volume', 'readCount')
    window_size = 7
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    raw_volume = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size)))
    click_count = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(click_count, window_size)))
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
    ax.plot(dates, volume, 'k-', label='Real')
    ax.plot(dates, prediction, 'k--', label='Prediction')
    ax.set_ylabel('Volume ratio')
    ax.set_xlabel('Date')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def sliding_ratio_forecast(func_name):
    index = 600036
    for window_size in range(2, 11):
        d = stats.data.get_merged_old(index, 'date', 'volume', 'readCount')
        dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
        raw_volume = d[:, 1].astype(float)
        click_count = d[:, 2].astype(float)
        volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size)))
        click_count = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(click_count, window_size)))
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
        if lag == 0:
            continue
        for j in range(lag, length):
            prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
        cnt = 0
        for j in range(lag, length):
            diff = prediction[j] - volume[j]
            cnt += diff ** 2
        print('{} {}: {}'.format(index, window_size,
            math.sqrt(cnt / (length - lag)) / (max(volume) - min(volume))))

@register_plot
def sliding_ratio_forecast_all(func_name):
    for index in stats.data.sse_indices():
        arr = []
        for window_size in range(2, 11):
            d = stats.data.get_merged_old(index, 'date', 'volume', 'readCount')
            dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
            raw_volume = d[:, 1].astype(float)
            click_count = d[:, 2].astype(float)
            volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size)))
            click_count = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(click_count, window_size)))
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
            if lag == 0:
                continue
            for j in range(lag, length):
                prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
            cnt = 0
            for j in range(lag, length):
                diff = prediction[j] - volume[j]
                cnt += diff ** 2
            nrmse = math.sqrt(cnt / (length - lag)) / (max(volume) - min(volume))
            arr.append((window_size, nrmse))
        print('{}: {}'.format(index, min(arr, key=lambda x: x[1])))

@register_plot
def sliding_ratio_window_selection(func_name):
    window_sizes = []
    for index in stats.data.sse_indices():
        arr = []
        for window_size in range(2, 11):
            d = stats.data.get_merged_old(index, 'date', 'volume', 'readCount')
            dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
            raw_volume = d[:, 1].astype(float)
            click_count = d[:, 2].astype(float)
            volume = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(raw_volume, window_size)))
            click_count = np.concatenate((np.zeros(window_size - 1,), stats.preprocess.sliding_ratio(click_count, window_size)))
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
            if lag == 0:
                continue
            for j in range(lag, length):
                prediction.append(results.forecast(data.values[j - lag: j], 1)[0][1])
            cnt = 0
            for j in range(lag, length):
                diff = prediction[j] - volume[j]
                cnt += diff ** 2
            nrmse = math.sqrt(cnt / (length - lag)) / (max(volume) - min(volume))
            arr.append((window_size, nrmse))
        window_sizes.append(min(arr, key=lambda x: x[1])[0])
    fig, ax = plt.subplots()
    index = np.arange(len(window_sizes))
    bar_width = 0.8
    plt.bar(index, np.asarray(window_sizes), bar_width, color='w', label='Window size')
    plt.xlabel('Stock')
    plt.ylabel('Window size')
    plt.legend(loc=0)
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def price_click_count_line(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'close', 'readCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    price = d[:, 1]
    click_count = d[:, 2]
    lines = []
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, price, 'k-', label='Price')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Price')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def price_click_count_lag_selection(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'close', 'readCount')
    close = d[:, 1].astype(float)
    click_count = d[:, 2].astype(float)
    data = pandas.DataFrame({'close': close,
        'clickCount': click_count})
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    with Capturing() as output:
        model.select_order()
    print('\n'.join(output))

@register_plot
def price_click_count_granger(func_name):
    d = stats.data.get_merged_old('600000', 'close', 'readCount')
    with Capturing() as output:
        statsmodels.tsa.api.stattools.\
                grangercausalitytests(d, 5, verbose=True)
    print('\n'.join(output))

@register_plot
def price_click_count_granger_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test'),
        ('params_ftest', 'Params $F$ test'),
        ('lrtest', 'LR test'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test'),
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
    index = np.arange(len(results))
    bar_width = 0.8
    for i in range(len(tests)):
        plt.bar(index, np.asarray(results)[:, i].flatten(), bar_width, color='w', label=tests[i][1])
        plt.xlabel('Stock')
        plt.ylabel('$p$ value')
        plt.legend(loc=0)
        plt.savefig('thesis/plots/{}_{}.pdf'.format(func_name, tests[i][0]))
        plt.clf()

@register_plot
def price_click_count_positive_line(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'close', 'readCount')
    ds = stats.data.get_merged('600000', 'positiveCount', 'negativeCount')
    dates = [datetime.datetime.strptime(i, '%Y-%m-%d') for i in d[:, 0]]
    price = d[:, 1]
    click_count = np.multiply(
            ds[:, 0].astype(float) / (ds[:, 0] + ds[:, 1]).astype(float),
            d[:, 2].astype(float))
    lines = []
    fig, ax0 = plt.subplots()
    ax1 = ax0.twinx()
    ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
    fig.autofmt_xdate()
    lines += ax0.plot(dates, price, 'k-', label='Price')
    ax0.set_xlabel('Date')
    ax0.set_ylabel('Price')
    lines += ax1.plot(dates, click_count, 'k:', label='Click count')
    ax1.set_ylabel('Click count')
    labels = [i.get_label() for i in lines]
    ax0.grid()
    ax0.legend(lines, labels, loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.pdf'.format(func_name))

@register_plot
def price_click_count_positive_lag_selection(func_name):
    d = stats.data.get_merged_old('600000', 'date', 'close', 'readCount')
    ds = stats.data.get_merged('600000', 'positiveCount', 'negativeCount')
    close = d[:, 1].astype(float)
    click_count = np.multiply(ds[:, 0].astype(float) / (ds[:, 0] + ds[:, 1]).astype(float), d[:, 2].astype(float))
    data = pandas.DataFrame({'close': close,
        'clickCount': click_count})
    data.index = pandas.DatetimeIndex(d[:, 0].astype(str))
    model = statsmodels.tsa.api.VAR(data)
    with Capturing() as output:
        model.select_order()
    print('\n'.join(output))

@register_plot
def price_click_count_positive_granger(func_name):
    d = stats.data.get_merged_old('600000', 'close', 'readCount')
    ds = stats.data.get_merged('600000', 'positiveCount', 'negativeCount')
    click_count = np.multiply(ds[:, 0].astype(float) / (ds[:, 0] + ds[:, 1]).astype(float), d[:, 1].astype(float))
    data = np.concatenate((np.expand_dims(d[:, 0], 1), np.expand_dims(click_count, 1)), axis=1)
    with Capturing() as output:
        statsmodels.tsa.api.stattools.\
                grangercausalitytests(data, 5, verbose=True)
    print('\n'.join(output))

@register_plot
def price_click_count_positive_granger_on_sse_50(func_name):
    results = []
    tests = [
        ('ssr_ftest', 'SSR $F$ test'),
        ('params_ftest', 'Params $F$ test'),
        ('lrtest', 'LR test'),
        ('ssr_chi2test', 'SSR $\chi^{2}$ test'),
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
    index = np.arange(len(results))
    bar_width = 0.8
    for i in range(len(tests)):
        plt.bar(index, np.asarray(results)[:, i].flatten(), bar_width, color='w', label=tests[i][1])
        plt.xlabel('Stock')
        plt.ylabel('$p$ value')
        plt.legend(loc=0)
        plt.savefig('thesis/plots/{}_{}.pdf'.format(func_name, tests[i][0]))
        plt.clf()

if __name__ == '__main__':
    for i in all_plots:
        i()
