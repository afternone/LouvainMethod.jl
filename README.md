# LouvainMethod

[![Build Status](https://travis-ci.org/afternone/LouvainMethod.jl.svg?branch=master)](https://travis-ci.org/afternone/LouvainMethod.jl)

##Usage
```
# read graph from file
g = readgraph(filename[, is_weighted=false, start_index=0])

# constuct community
c = community(g)

# greedy optimize modularity
tree = louvain(c)

# transform tree to partition
membership = tree2partition(tree)
```
