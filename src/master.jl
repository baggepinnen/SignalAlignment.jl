abstract type MasterMethod end
struct Index <: MasterMethod
    i::Int
end
struct Longest <: MasterMethod end
struct Shortest <: MasterMethod end
struct Centroid{D} <: MasterMethod
    dist::D
end
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