import matplotlib.pyplot as plt
import numpy as np
import matplotlib.dates
from datetime import date

def twin_x(data, labels=None, x=None):
    if not isinstance(data, np.ndarray):
        data = np.asarray(data)
    assert(data.ndim == 2)
    assert(data.shape[1] == 2)
    if x == None:
        x = np.arange(data.shape[0])
    fig, ax1 = plt.subplots()
    ax1.plot(x, data[:, 0], 'b')
    for i in ax1.get_yticklabels():
        i.set_color('b')
    ax1.get_yaxis().get_offset_text().set_color('b')
    try:
        ax1.set_ylabel(labels[0], color='b')
    except:
        ax1.set_ylabel('', color='b')
    if isinstance(x[0], date):
        ax1.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
        fig.autofmt_xdate()
    ax2 = ax1.twinx()
    ax2.plot(x, data[:, 1], 'r')
    for i in ax2.get_yticklabels():
        i.set_color('r')
    ax2.get_yaxis().get_offset_text().set_color('r')
    try:
        ax2.set_ylabel(labels[1], color='r')
    except:
        ax2.set_ylabel('', color='r')
    plt.show()

def single_x(data, x=None):
    fig, ax0 = plt.subplots()
    if not isinstance(data, np.ndarray):
        data = np.asarray(data)
    data = data.flatten()
    if x == None:
        x = np.arange(data.shape[0])
    elif isinstance(x[0], date):
        ax0.fmt_xdata = matplotlib.dates.DateFormatter('%Y-%m-%d')
        fig.autofmt_xdate()
    ax0.plot(x, data)
    plt.show()
