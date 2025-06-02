# 2 times faster than Base.extrema, but maybe unsafe
function fastextrema(x)
    mini = x |> eltype |> typemax
    maxi = x |> eltype |> typemin
    for v in x
        if v < mini
            mini = v
        end
        if v > maxi
            maxi = v
        end
    end
    return mini, maxi
end

fastextrema(x::AbstractArray{T}) where T<:AbstractFloat = fastextrema(skip(isnan, x))

#=
function extremaz(::Type{SingleThread}, x) # 2 fois plus rapide que extrema
    mini = x |> eltype |> typemax
    maxi = x |> eltype |> typemin
    for v in x
        if v < mini
            mini = v
        end
        if v > maxi
            maxi = v
        end
    end
    return mini, maxi
end

function extremaz(::Type{MultiThreads}, x)
    mini = x |> eltype |> typemax
    maxi = x |> eltype |> typemin
    minith = [mini for _ in 1:nthreads()]
    maxith = [mini for _ in 1:nthreads()]
    @threads for v in x
        if v < minith[threadid()]
            mini = v
        end
        if v > maxith[threadid()]
            maxi = v
        end
    end
    return minimum(minith), maximum(maxith)
end

extremaz(::Type{SingleThread}, x::AbstractArray{T}) where T<:AbstractFloat = extremaz(SingleThread, skip(isnan, x))

extremaz(::Type{MultiThreads}, x::AbstractArray{T}) where T<:AbstractFloat = extremaz(MultiThreads, skip(isnan, x))

extremaz(x) = extremaz(SingleThread, x)
=#

#= pas plus rapide
function fmin(x) # benchmark avec Skipper pour abstract float
    a = first(x)
    for v in x
        v < a && (a = v)
    end
    return a
end

fmin(x::AbstractArray{T}) where T<:AbstractFloat = fmin(skip(isnan, x))

function fmax(x) # benchmark avec Skipper pour abstract float
    b = first(x)
    for v in x
        v > b && (b = v)
    end
    return b
end

fmax(x::AbstractArray{T}) where T<:AbstractFloat = fmax(skip(isnan, x))

=#
