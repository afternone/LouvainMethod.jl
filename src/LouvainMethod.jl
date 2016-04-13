module LouvainMethod

export
  rename,
  readgraph,
  louvain,
  community,
  tree2partition

include("graph.jl")
include("community.jl")
include("utils.jl")

end # module
