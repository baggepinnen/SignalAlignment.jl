abstract type AbstractOutput end

Base.@kwdef struct Indices <: AbstractOutput
    crop::Bool = true
end

Base.@kwdef struct Signals <: AbstractOutput
end

function get_output(inds, signals, output::Indices)
    inds
end

function get_output(inds, signals, output::Signals)
    [s[!,i] for (s,i) in zip(signals,inds)]
end

function recompute_indices(i1, i2)
    out = Tuple{Int, Int}[]
    i = j = 1
    while i < length(i1) && j < length(i2)
        push!(out, (i1[i],i2[j]))
        upi = i1[i] == i1[i+1]
        upj = i2[j] == i1[j+1]
        if !(upj || upi)
            upj = upi = true
        end
        i += upi
        j += upj
    end
    first.(out), last.(out)
    # i1
end

function align2second(i1, i2)
    out = Tuple{Int, Int}[]
    j = 1
    map(1:i2[end]) do i
        j0 = findfirst(>(i-1), i2)
        j1 = findlast(<=(i), i2)
        j = j1 === nothing ? j : floor(Int, 0.5*(j0 + j1))
        i1[j]
    end
end