import numpy as np

def sliding_ratio(data, window_size):
    return np.asarray(
            [data[i] / np.min(data[i - window_size + 1:i + 1])
                for i in range(window_size - 1, len(data))])

