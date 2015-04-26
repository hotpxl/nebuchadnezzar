import matplotlib.pyplot as plt
import numpy as np

def twin_x(data, x=None):
    if not isinstance(data, np.ndarray):
        data = np.asarray(data)
    assert(data.ndim == 2)
    assert(data.shape[1] == 2)
    if x == None:
        x = np.arange(data.shape[0])
    fix, ax1 = plt.subplots()
    ax1.plot(x, data[:, 0], 'b')
    for i in ax1.get_yticklabels():
        i.set_color('b')
    ax1.set_ylabel('', color='b')
    ax2 = ax1.twinx()
    ax2.plot(x, data[:, 1], 'r')
    for i in ax2.get_yticklabels():
        i.set_color('r')
    plt.show()

def single_x(data, x=None):
    if not isinstance(data, np.ndarray):
        data = np.asarray(data)
    data = data.flatten()
    if x == None:
        x = np.arange(data.shape[0])
    plt.plot(x, data)
