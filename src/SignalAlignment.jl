module SignalAlignment
using Statistics
using Distances
using DSP

export DTW
using DynamicAxisWarping
using DynamicAxisWarping.SlidingDistancesBase


## Outputs
export Indices, Signals, get_output
include("outputs.jl")

## Master methods
export get_master
export Index, Longest, Shortest, Centroid, Barycenter
include("master.jl")

## Methods
export compute_aligning_indices
export Delay, XcorrDelay, DTWDelay, compute_delay
export Warp
include("methods.jl")

## By
export get_alignment_signals
include("by.jl")

## Main algorithm
export align_signals
function align_signals(signals, method; master = Index(1), by=nothing, output = Indices())
    s = get_alignment_signals(signals, by)
    inds = compute_aligning_indices(s, method; master)
    get_output(inds, signals, output)
end

end
