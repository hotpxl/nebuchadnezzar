#!/usr/bin/env python3.4
import json
from matplotlib.pyplot import *
import numpy as np

with open('./tmp/600000.json') as f:
    orig = json.load(f)
volume = np.asarray([x['volume'] for x in orig])
plot(volume)
show()
for windowSize in range(2, 20):
    p = [np.max(volume[i:i + windowSize]) for i in range(len(volume))]
    print(windowSize)
    plot(p)
    show()

