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