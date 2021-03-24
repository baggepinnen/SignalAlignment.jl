abstract type AbstractMethod end


## Delay method
abstract type AbstractDelayMethod end
struct XcorrDelay <: AbstractDelayMethod end
struct DTWDelay <: AbstractDelayMethod end

Base.@kwdef struct Delay <: AbstractMethod
    delay_method = DTWDelay()
end


function compute_delay(method::DTWDelay, s1, s2)
    d,i1,i2 = dtw(s1, s2)
    round(Int, median(i1-i2))
end

function compute_delay(method::XcorrDelay, s1, s2)
    DSP.finddelay(s1, s2)
end



function compute_aligning_indices(s, method::Delay; master)
    sm = get_master(master, s)
    inds = [1:lastlength(s) for s in s]
    # find delays to align with master
    d = map(s) do si
        si === sm && (return 0)
        compute_delay(method.delay_method, sm, si)
    end

    # find left and right (virtual) zero padding
    lp = maximum(d)
    rp = maximum(length(sm) .- (length.(s) .+ d))
    
    # New window length
    wl = lastlength(sm) - lp - rp
    
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
    warp_method::T
end

function compute_aligning_indices(s, method::Warp{<:DTW}; master) # TODO, maybe the inner method has options
    sm = get_master(master, s)
    d = method.warp_method
    # find delays to align with master
    inds = map(s) do si
        si === sm && (return collect(1:lastlength(sm)))
        _,i1,i2 = distpath(d, si, sm)
        # i1
        # i1_, i2_ = recompute_indices(i1,i2)
        # i1_
        align2second(i1,i2)
    end
    inds
end


function align_signals(signals, method::Warp{<:DynamicAxisWarping.GDTW}; master = Index(1), by=nothing, output = Signals())

    sm = get_master(master, signals)
    ts = LinRange(0, 1, lastindex(sm))
    y = LinearInterpolation(sm)
    kwargs = method.warp_method.opts
    res = map(signals) do si
        # si === sm && (return y)
        x = LinearInterpolation(si)
        d,i1,i2 = gdtw(x, y; symmetric=true, kwargs...)
        if output isa Indices
            return i1
        else
            si === sm && x.(ts)
            r = x.(i1.(ts))
            sm isa AbstractVector{<:Number} ? r : reduce(hcat, r)
        end
    end
    res
end

