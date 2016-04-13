immutable Edge{V,W}
    dest::V
    weight::W
end

type Graph{V,W}
    links::Vector{Vector{Edge{V,W}}}
    selfloops::Vector{W}
end

function readgraph(filename; is_weighted=false, start_index=0)
    links = Vector{Vector{Edge{Int,Float64}}}()
    selfloops = Float64[]
    open(filename, "r") do f
        for line in eachline(f)
            if line[1] != '#'
                items = split(line)
                src = parse(Int64, items[1]) + 1 - start_index
                dest = parse(Int64, items[2]) + 1 - start_index
                weight = is_weighted ? parse(Float64, items[3]) : 1.
                maxid = max(src,dest)
                if length(links) < maxid
                    resizevec!(links, maxid)
                    resizevec!(selfloops, maxid)
                end
                if src == dest
                    selfloops[src] = weight
                else
                    push!(links[src], eltype(eltype(links))(dest,weight))
                    push!(links[dest], eltype(eltype(links))(src,weight))
                end
            end
        end
    end
    Graph(links, selfloops)
end

function rename(filename)
  nodemap = Dict{Any,Int}()
  j = 1
  open(filename, "r") do f
    for line in eachline(f)
      if line[1] != '#'
        items = split(line)
        src = items[1]
        dest = items[2]
        if !haskey(nodemap, src)
          nodemap[src] = j
          j += 1
        end
        if !haskey(nodemap, dest)
          nodemap[dest] = j
          j += 1
        end
      end
    end
  end
  fout = open(splitext(filename)[1]*".renamed", "w")
  open(filename, "r") do f
    for line in eachline(f)
      if line[1] != '#'
        items = split(line)
        src = items[1]
        dest = items[2]
        weight = length(items) > 2 ? parse(Float64, items[3]) : 1.
        println(fout, nodemap[src], ' ', nodemap[dest], ' ', weight)
      end
    end
  end
  close(fout)
end


function weighted_degree(g, u)
    res = 0.
    for out_edge in g.links[u]
        res += out_edge.weight
    end
    res + g.selfloops[u]
end

function total_weight(g)
    totw = 0.
    for u in eachindex(g.links)
        totw += weighted_degree(g,u)
    end
    totw
end

function total_links(g)
    nblinks = 0
    for u in eachindex(g.links)
        nblinks += g.selfloops[u]>0. ? length(g.links[u])+1 : length(g.links[u])
    end
    div(nblinks,2)
end
