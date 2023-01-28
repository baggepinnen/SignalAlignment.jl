abstract type MasterMethod end
"""
    Index(i)

Align all signals to the signal with index `i`.

# Fields:
- `i::Int`
"""
struct Index <: MasterMethod
    i::Int
end

"""
    Longest

Align all signals to the longest signal
"""
struct Longest <: MasterMethod end

"""
    Shortest

Align all signals to the shortest signal
"""
struct Shortest <: MasterMethod end

"""
    Centroid{D}

Align all signals to the centroid (generalized median).

# Fields:
- `dist::D`: Metric used to compute the centroid, e.g., Distances.SqEuclidean`.
"""
struct Centroid{D} <: MasterMethod
    dist::D
end

"""
    Barycenter{D}

Align all signals to the barycenter (generalized mean).

# Fields:
- `dist::D`: Metric used to compute the barycenter, e.g., Distances.SqEuclidean`.
"""
struct Barycenter{D} <: MasterMethod
    dist::D
end

function get_master(method::Index, s)
    return s[method.i]
end

function get_master(i::Int, s)
    return s[i]
end

function get_master(method::Longest, s)
    return s[argmax(lastlength.(s))]
end

function get_master(method::Shortest, s)
    return s[argmin(lastlength.(s))]
end

function get_master(method::Centroid, s)
    D = Distances.pairwise(method.dist, s, s)
    Dm = vec(mean(D, dims=2))
    s[argmin(Dm)]
end

function get_master(method::Barycenter{Euclidean}, s)
    mean(s)
end

function get_master(method::Barycenter{<:DTW}, s)
    bc, _ = dba(s, method.dist) # TODO: maybe use SoftDTW instead
    bc
end