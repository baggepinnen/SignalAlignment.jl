function get_alignment_signals(signals::AbstractVector{<:AbstractArray}, ::Nothing)
    signals
end

function get_alignment_signals(signals, by::Function)
    by.(signals)
end

function get_alignment_signals(signals::AbstractVector{<:AbstractArray}, by::Union{Integer, AbstractVector})
    [s[by, :] for s in signals]
end
