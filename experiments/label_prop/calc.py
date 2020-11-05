import sys
from collections import defaultdict
import pandas as pd

def str_to_sec(s: str) -> float:
    if s[-2:] == "ms":
        return float(s[:-2])/1000
    else:
        return float(s[:-1])

data = defaultdict(list)

f = open(sys.argv[1])
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

print(data["wiki-Talk_hilbert_io"])
df = pd.DataFrame.from_dict(data, orient='index')
print(df.std(axis=1))
