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
    warp_method::T = DTW
end

function compute_aligning_indices(s, method::Warp{<:DTW}; master) # TODO, maybe the inner method has options
    sm = get_master(master, s)
    d = method.warp_method
    # find delays to align with master
    inds = map(s) do si
        si === sm && (return collect(1:lastlength(sm)))
        _,i1,i2 = distpath(d, si, sm)
        i1
    end
    inds
end

# function compute_aligning_indices(s, method::Warp{<:GDTW}) # TODO, maybe the inner method has options
#     sm = get_master(master, s)
#     # find delays to align with master
#     inds = map(s) do si
#         y = LinearInterpolation(sm)
#         si === sm && (return y)
#         x = LinearInterpolation(si)
#         d,i1,i2 = gdtw(x, y)
#         i1
#     end
#     @assert all(length.(inds) .== length(inds[1])) # TODO: figure this out

#     inds
# end