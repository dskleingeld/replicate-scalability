from collections import defaultdict
import re
import pandas as pd
import seaborn as sns
import matplotlib.pyplot as plt

# sns.set_theme(style="ticks")
sns.set_theme(style="whitegrid")

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

df = defaultdict(list)
for (dataset, measurements) in data.items():
    df["dataset"].append(dataset)
    for (cores, measurement) in measurements.items():
        df[int(cores)].append(measurement[0])

tips = sns.load_dataset("tips")
df = pd.DataFrame.from_dict(df)
df = df.melt(id_vars="dataset", var_name="cores", value_name="runtime")
f, ax = plt.subplots(figsize=(7,6))

#try sns.boxplot
sns.stripplot(hue="dataset", x="cores", y="runtime", data=df)
plt.show()
