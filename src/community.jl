type Community
    g::Graph{Int,Float64}
    n2c::Vector{Int}
    in_w::Vector{Float64}
    tot_w::Vector{Float64}
    neigh_pos::Vector{Int}
    neigh_weight::Vector{Float64}
    neigh_last::Int
end

function community{V,W}(g::Graph{V,W})
    N = length(g.links)
    n2c = collect(1:N)
    in_w = Array(Float64,N)
    tot_w = Array(Float64,N)
    neigh_pos = ones(Int, N)
    neigh_weight = fill(-1., N)
    for u in eachindex(g.links)
        in_w[u] = g.selfloops[u]
        tot_w[u] = weighted_degree(g,u)
    end
    Community(g , n2c, in_w, tot_w, neigh_pos, neigh_weight, 1)
end

function removenode!(c, u, comm, dnodecomm, w_degrees)
    c.tot_w[comm] -= w_degrees[u]
    c.in_w[comm] -= 2dnodecomm + c.g.selfloops[u]
    c.n2c[u] = -1
end

function insertnode!(c, u, comm, dnodecomm, w_degrees)
    c.tot_w[comm] += w_degrees[u]
    c.in_w[comm] += 2dnodecomm + c.g.selfloops[u]
    c.n2c[u] = comm
end

function modularity_gain(c,u,comm,dnodecomm,w_degree, totw)
    dnodecomm - c.tot_w[comm]*w_degree/totw
end

function modularity(c, totw)
    q = 0.
    for i=1:length(c.g.links)
        if c.tot_w[i] > 0
            q += c.in_w[i]/totw - (c.tot_w[i]/totw)*(c.tot_w[i]/totw)
        end
    end
    q
end

function neigh_comm!(c, u)
    for i=1:c.neigh_last-1
        c.neigh_weight[c.neigh_pos[i]] = -1.
    end
    c.neigh_last = 1
    c.neigh_pos[1] = c.n2c[u]
    c.neigh_weight[c.neigh_pos[1]] = 0.
    c.neigh_last = 2
    for out_edge in c.g.links[u]
        neigh = out_edge.dest
        neigh_comm = c.n2c[neigh]
        neigh_w = out_edge.weight
        if neigh != u
            if c.neigh_weight[neigh_comm] < 0.
                c.neigh_weight[neigh_comm] = 0.
                c.neigh_pos[c.neigh_last] = neigh_comm
                c.neigh_last += 1
            end
            c.neigh_weight[neigh_comm] += neigh_w
        end
    end
end

function partition2graph!(c)
    renumber!(c.n2c)
    Nc = maximum(c.n2c)
    linkdic = Dict{Int,Float64}[]
    resizevec!(linkdic, Nc)
    selfloops = zeros(Nc)
    for u in eachindex(c.g.links)
        selfloops[c.n2c[u]] += c.g.selfloops[u]
        for out_edge in c.g.links[u]
            if out_edge.dest > u
                comm1, comm2 = minmax(c.n2c[u], c.n2c[out_edge.dest])
                if comm1 != comm2
                    linkdic[comm1][comm2] = get(linkdic[comm1], comm2, 0.) + out_edge.weight
                else
                    selfloops[comm1] += 2out_edge.weight
                end
            end
        end
    end
    links = Vector{Vector{Edge{Int,Float64}}}()
    resizevec!(links, Nc)
    for u in eachindex(linkdic)
        for (v,w) in linkdic[u]
            push!(links[u], eltype(eltype(links))(v,w))
            push!(links[v], eltype(eltype(links))(u,w))
        end
    end
    Graph(links, selfloops)
end

function one_level!(c, totw, w_degrees; min_modularity=0.0001)
    N = length(c.g.links)
    improvement = false
    nb_moves = 1
    nb_pass_done = 0
    cur_mod = modularity(c, totw)
    new_mod = cur_mod + 2min_modularity
    random_order = collect(1:N)
    shuffle!(random_order)
    while nb_moves>0 && new_mod-cur_mod>min_modularity
        cur_mod = new_mod
        nb_moves = 0
        nb_pass_done += 1
        for node in random_order
            node_comm = c.n2c[node]
            #w_degree = weighted_degree(c.g, node)
            w_degree = w_degrees[node]
            neigh_comm!(c, node)
            removenode!(c, node, node_comm, c.neigh_weight[node_comm], w_degrees)
            best_comm = node_comm
            best_nblinks = 0.
            best_increase = 0.
            for i=1:c.neigh_last-1
                increase = modularity_gain(c, node, c.neigh_pos[i], c.neigh_weight[c.neigh_pos[i]], w_degree, totw)
                if increase > best_increase
                    best_comm = c.neigh_pos[i]
                    best_nblinks = c.neigh_weight[c.neigh_pos[i]]
                    best_increase = increase
                end
            end
            insertnode!(c, node, best_comm, best_nblinks, w_degrees)
            if best_comm != node_comm
                nb_moves += 1
            end
        end
        new_mod = modularity(c, totw)
        if nb_moves > 0
            improvement = true
        end
    end
    improvement
end

function louvain(c; min_modularity=0.0001, verbose=true)
    N = length(c.g.links)
    totw = total_weight(c.g)
    tree = Array(Int, 0, 2)
    improvement = true
    q = modularity(c, totw)
    q1 = q + 2min_modularity
    level = 0
    w_degrees = Array(Float64, N)
    while improvement
        nblinks = total_links(c.g)
        resize!(w_degrees, length(c.g.links))
        for i in eachindex(w_degrees)
          w_degrees[i] = weighted_degree(c.g, i)
        end
        if verbose
            println("level: ", level)
            println(" network size: ", length(c.g.links), " nodes, ",
            nblinks, " links, ", totw, " weight.")
        end
        improvement = one_level!(c, totw, w_degrees, min_modularity=min_modularity)
        q1 = modularity(c, totw)
        g = partition2graph!(c)
        tree = vcat(tree, [collect(1:length(c.n2c)) c.n2c])
        c = community(g)
        if verbose
            println(" modularity increased from ", q, " to ", q1)
        end
        q = q1
        level += 1
    end
    tree
end

function tree2partition(tree)
    levels = Vector{Int}[]
    l = 0
    for i=1:size(tree,1)
        node = tree[i,1]
        nodecomm = tree[i,2]
        if node == 1
            l += 1
            resizevec!(levels, l)
        end
        push!(levels[l], nodecomm)
    end
    n2c = collect(1:length(levels[1]))
    for l in eachindex(levels)
        for node=1:length(levels[1])
            n2c[node] = levels[l][n2c[node]]
        end
    end
    n2c
end
