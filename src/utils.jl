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
