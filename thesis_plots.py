#!/usr/bin/env python3.4
import sys
import io
import stats.data
import stats.plot
import datetime
import matplotlib.pyplot as plt
import matplotlib.dates
import pandas
import statsmodels.tsa.api
import statsmodels.tsa.stattools

def register_plot(func):
    def ret(*args, **kwargs):
        kwargs['func_name'] = func.__name__
        return func(*args, **kwargs)
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
    # plt.show()
    plt.savefig('thesis/plots/{}.png'.format(func_name))

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
    d = stats.data.get_merged('600000', 'volume', 'clickCount')
    with Capturing() as output:
        statsmodels.tsa.api.stattools.\
        grangercausalitytests(d, 5, verbose=True)
    print('\n'.join(output))

@register_plot
def granger_causality_test_1(func_name):
    d = stats.data.get_merged('600000', 'volume', 'clickCount')
    max_lag = 5
    res = statsmodels.tsa.api.stattools.\
    grangercausalitytests(d, max_lag, verbose=False)
    ssr_chi2test = []
    params_ftest = []
    lrtest = []
    ssr_ftest = []
    for i in range(1, max_lag):
        ssr_chi2test.append(res[i][0]['ssr_chi2test'][1])
        params_ftest.append(res[i][0]['params_ftest'][1])
        lrtest.append(res[i][0]['lrtest'][1])
        ssr_ftest.append(res[i][0]['ssr_ftest'][1])
    x_axis = range(1, max_lag)
    fig, ax = plt.subplots()
    ax.plot(x_axis, ssr_chi2test, 'k-', label='SSR $\chi^{2}$ test')
    ax.plot(x_axis, params_ftest, 'k--', label='Params $F$ test')
    ax.plot(x_axis, lrtest, 'k:', label='LR $\chi^{2}$ test')
    ax.plot(x_axis, ssr_ftest, 'k-.', label='SSR $F$ test')
    ax.set_ylabel('$p$ value')
    ax.set_xlabel('lag value')
    ax.grid()
    ax.legend(loc=0)
    plt.tight_layout()
    plt.savefig('thesis/plots/{}.png'.format(func_name))


if __name__ == '__main__':
    # auto_regression_0()
    # auto_regression_1()
    granger_causality_test_1()
