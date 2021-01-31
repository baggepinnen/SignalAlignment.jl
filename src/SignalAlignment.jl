module SignalAlignment
using Statistics
using DSP
using DynamicAxisWarping
using DynamicAxisWarping.SlidingDistancesBase

export Indices, Signals, get_output
export Delay, XcorrDelay, DTWDelay, compute_delay
export Warp
export align_signals, compute_aligning_indices, get_alignment_signals

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


## Methods
abstract type AbstractMethod end


## Delay method
abstract type AbstractDelayMethod end
struct XcorrDelay <: AbstractDelayMethod end
struct DTWDelay <: AbstractDelayMethod end

Base.@kwdef struct Delay <: AbstractMethod
    delay_method = DTWDelay()
    master::Int
end


function compute_delay(method::DTWDelay, s1, s2)
    d,i1,i2 = dtw(s1, s2)
    round(Int, median(i1-i2))
end

function compute_delay(method::XcorrDelay, s1, s2)
    DSP.finddelay(s1, s2)
end



function compute_aligning_indices(s, method::Delay)
    master = method.master
    inds = [1:lastlength(s) for s in s]
    # find delays to align with master
    d = map(s) do si
        si === s[master] && (return 0)
        compute_delay(method.delay_method, s[master], si)
    end

    # find left and right (virtual) zero padding
    lp = maximum(d)
    rp = maximum(length(s[master]) .- (length.(s) .+ d))
    
    # New window length
    wl = length(inds[master]) - lp - rp
    
    # trim individual index sets to fit into new master window
    for i in eachindex(inds)
        start = max(1, 1+lp-d[i])
        stop = min(length(s[i]),start+wl-1)
        inds[i] = start : stop
    end
    @assert all(length.(inds) .== length(inds[1]))
    inds
end


## Warp method
Base.@kwdef struct Warp{T} <: AbstractMethod
    warp_method::T = DTW
    master::Int
end

function compute_aligning_indices(s, method::Warp{<:DTW}) # TODO, maybe the inner method has options
    master = method.master
    d = method.warp_method
    # find delays to align with master
    inds = map(s) do si
        si === s[master] && (return collect(1:lastlength(s[master])))
        _,i1,i2 = distpath(d, si, s[master])
        i1
    end
    inds
end

# function compute_aligning_indices(s, method::Warp{<:GDTW}) # TODO, maybe the inner method has options
#     master = method.master
#     # find delays to align with master
#     inds = map(s) do si
#         y = LinearInterpolation(s[master])
#         si === s[master] && (return y)
#         x = LinearInterpolation(si)
#         d,i1,i2 = gdtw(x, y)
#         i1
#     end
#     @assert all(length.(inds) .== length(inds[1])) # TODO: figure this out

#     inds
# end

function get_alignment_signals(signals::AbstractVector{<:AbstractArray}, ::Nothing)
    signals
end

function get_alignment_signals(signals, by::Function)
    by.(signals)
end

function get_alignment_signals(signals::AbstractVector{<:AbstractArray}, by::Union{Integer, AbstractVector})
    [s[by, :] for s in signals]
end

## Main algorithm

function align_signals(signals, method; by=nothing, output = Indices())
    s = get_alignment_signals(signals, by)
    inds = compute_aligning_indices(s, method)
    get_output(inds, signals, output)
end

end
