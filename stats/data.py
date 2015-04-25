import json
import os.path

p = os.path.dirname(os.path.realpath(__file__))

def sse_indices():
    with open(os.path.join(p, '../data/sse_50.json')) as f:
        sse_indices = json.load(f)
    return sse_indices

def get_merged(index, *fields):
    with open(os.path.join(p, '../tmp/{}.json'.format(index))) as f:
        data = json.load(f)
    return [[x[j] for j in fields] for x in data]