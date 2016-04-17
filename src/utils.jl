function resizevec!(vec, n)
    l = length(vec)
    if l < n
        resize!(vec, n)
        for i=l+1:n
            vec[i] = eltype(vec)()
        end
    end
end

function resizevec!(vec::Vector{Float64}, n)
    l = length(vec)
    if l < n
        resize!(vec, n)
        for i=l+1:n
            vec[i] = 0.
        end
    end
end

function renumber!(membership::Vector{Int})
    N = length(membership)
    if maximum(membership) > N || minimum(membership) < 1
        error("Label must between 1 and |V|")
    end
    label_counters = zeros(Int, N)
    j = 1
    for i=1:length(membership)
        k = membership[i]
        if k >= 1
            if label_counters[k] == 0
                # We have seen this label for the first time
                label_counters[k] = j
                k = j
                j += 1
            else
                k = label_counters[k]
            end
        end
        membership[i] = k
    end
end

function tree2partition(levels::Vector{Vector{Int}}; level=length(levels))
    (level >= 1 && level <= length(levels)) || error("level must in [1,$(length(levels))]")
    n = length(levels[1])
    n2c = collect(1:n)
    for l=1:level
        for node=1:n
            n2c[node] = levels[l][n2c[node]]
        end
    end
    n2c
end

function tree2partition(levels::Vector{Int}, level_sizes::Vector{Int}; level=length(level_sizes))
    (level >= 1 && level <= length(level_sizes)) || error("level must in [1,$(length(level_sizes))]")
    n = level_sizes[1]
    n2c = collect(1:n)
    level_start = 0
    for i=1:level
        for node=1:n
            n2c[node] = levels[n2c[node]+level_start]
        end
        level_start += level_sizes[i]
    end
    n2c
end

level_size
tree = [1,1,2,2,3,3,1,1,2,1,1]
level_size = [6, 3, 2]
tree2partition(tree, level_size, level=1)
l1 = [1,1,2,2,3,3]
l2 = [1,1,2]
l3 = [1,1]
levels = Array(Vector{Int},3)
levels[1] = l1
levels[2] = l2
levels[3] = l3
tree2partition(levels, level=1)
