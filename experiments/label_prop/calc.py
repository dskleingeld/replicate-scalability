from collections import defaultdict
import re
import pandas as pd
import numpy as np
import seaborn as sns
import matplotlib.pyplot as plt

data = defaultdict(lambda: defaultdict(list) )
f = open("single-threaded-stats.txt")
lines = f.readlines()

i = 0
key = None
order = None
time = None
is_numb = re.compile('[0-9]+\.[0-9]+')
while i < len(lines):
    if lines[i].startswith("dataset: "):
        key = lines[i][len("dataset: "):-1]
    elif lines[i].startswith("vertex"):
        order = "vertex"
    elif lines[i].startswith("hilbert"):
        order = "hilbert"
    elif is_numb.match(lines[i]):
        time = float(lines[i][:-1])

    if key is not None and order is not None and time is not None:
        data[key][order].append(time)
        order = None
        time = None
    i+=1

# print(data["wiki-Talk"])
df = pd.DataFrame.from_dict(data)
df_mean = df.applymap(lambda x: np.mean(np.array(x)))
df_std = df.applymap(lambda x: np.std(np.array(x)))
print(df_mean)
print(df_std)
# print("samples: ", len(data["graph500-25_vertex_ram"]))
