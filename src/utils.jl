function minmax(x) # benchmark avec Skipper pour abstract float
    #a = b = x[1] #first(x)
    a = x |> eltype |> typemax
    b = x |> eltype |> typemin
    for v in x
        v > b && (b = v)
        v < a && (a = v)
    end
    return a, b
end

minmax(x::AbstractArray{T}) where T<:AbstractFloat = minmax(skip(isnan, x))


#= pa plus rapide
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