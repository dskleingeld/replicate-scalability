from collections import defaultdict
import re
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# sns.set_theme(style="whitegrid")

###################################### SINGLE #######################################
def str_to_sec(s: str) -> float:
    if s[-2:] == "ms":
        return float(s[:-2])/1000
    else:
        return float(s[:-1])

data = defaultdict(list)
f = open("single-threaded-stats.txt")
lines = f.readlines()

i = 0
while i+6 < len(lines):
    if lines[i].startswith("dataset: "):
        key = lines[i][len("dataset: "):-1]
        data[key+"_vertex_ram"].append( str_to_sec(lines[i+3][len("excluding IO "):-1]))
        data[key+"_vertex_io"].append( float(lines[i+4][:-2]))
        data[key+"_hilbert_ram"].append( str_to_sec(lines[i+6][len("excluding IO "):-1]))
        data[key+"_hilbert_io"].append( float(lines[i+7][:-2]))
    i+=1

df = pd.DataFrame.from_dict(data, orient='index')
df = pd.concat([df.mean(axis=1),df.std(axis=1),df.var(axis=1)], axis=1)
df.columns = ["mean","std","var"]

# print("samples: ", len(data["graph500-25_vertex_ram"]))
# print(df)
######################################## SPARK ##########################################

data = defaultdict(lambda: defaultdict(list) )
f = open("scalable-stats.txt")
lines = f.readlines()

i = 0
key = None
cores= None
time = None
is_numb = re.compile('[0-9]+\.[0-9]+')
while i < len(lines):
    if lines[i].startswith("dataset: "):
        key = lines[i][len("dataset: "):-1]
    elif lines[i].startswith("total_cores: "):
        cores = int (lines[i][len("total_cores: "):-1])
    elif is_numb.match(lines[i]):
        time = float(lines[i][:-1])

    if key is not None and cores is not None and time is not None:
        data[key][cores].append(time)
        key = None
        cores = None
        time = None
    i+=1

data["datagen-8_0-fb"][2] = [0]
print(pd.DataFrame.from_dict(data))

df = defaultdict(list)
for (dataset, measurements) in data.items():
    df["dataset"].append(dataset)
    for (cores, measurement) in measurements.items():
        df[int(cores)].append(measurement)

df2 = pd.DataFrame(columns=["dataset", "cores", "runtime"])
df = pd.DataFrame.from_dict(df)
df = df.melt(id_vars="dataset", var_name="cores", value_name="runtime")

for row in map(lambda x: x[1], df.iterrows()):
    values = [[row["dataset"], row["cores"], m] for m in row["runtime"]]
    df3 = pd.DataFrame(values, columns=["dataset", "cores", "runtime"])
    df2 = df2.append(df3,ignore_index=True)


import matplotlib  as mpl
mpl.rcParams["axes.formatter.useoffset"] = False

# print(df2)
plt.rcParams.update({'font.size': 16})
f, ax = plt.subplots(figsize=(10,6))

sns.stripplot(hue="dataset", x="cores", y="runtime", data=df2, size=4, linewidth=0)
sns.boxplot(hue="dataset", x="cores", y="runtime", data=df2, whis=[0,100], width=.6, saturation=0.6, dodge=True)

ax.xaxis.grid(True)
ax.set(ylabel="")
sns.despine(trim=True, left=True)
plt.yscale('log')

import matplotlib.ticker as mticker
ax.get_yaxis().set_major_formatter(mticker.ScalarFormatter())
ax.get_yaxis().get_major_formatter().set_scientific(False)
ax.get_yaxis().set_minor_formatter(mticker.ScalarFormatter())
ax.get_yaxis().get_minor_formatter().set_scientific(False)

plt.legend(bbox_to_anchor=(1.01, 1),borderaxespad=0)
plt.tight_layout()
plt.savefig("../../report/images/pagerank.png")
plt.show()
