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
