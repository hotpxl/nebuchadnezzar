import numpy as np

def slidingRatio(data, windowSize):
    return np.asarray([data[i] / np.min(data[i - windowSize + 1:i + 1]) for i in range(windowSize - 1, len(data))])

