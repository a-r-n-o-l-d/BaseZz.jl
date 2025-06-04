########################################################################################################################
#                                                   COMMON UTILITIES                                                   #
########################################################################################################################

# 1. Type aliases
# ---------------

const IntegerPixel{T<:Integer} = Union{T,AbstractGray{T}}
const RealPixel{T<:Real} = Union{T,AbstractGray{T}}
const FloatPixel{T<:AbstractFloat} = Union{T,AbstractGray{T}}
const ComplexPixel{T<:Complex} = Union{T,AbstractGray{T}}

const RealImage{T<:RealPixel,N} = AbstractArray{T,N}
const FloatImage{T<:FloatPixel,N} = AbstractArray{T,N}

const RealSkipper{P,A<:RealImage} = Skipper.Skip{P,A}
const GenericRealImageSkipper = Union{RealImage,RealSkipper}

const MultiChannelRealPixel{T<:Real,N} = Color{T,N}
const MultiChannelRealImage{T<:MultiChannelRealPixel,N} = AbstractArray{T,N}

const MultiChannelRealSkipper{P,A<:MultiChannelRealImage} = Skipper.Skip{P,A}


# 2. Functions: isnotnumber & isnumber
# ------------------------------------

"""
isnumber(x) -> Bool

Check if `x` is a valid number.

Returns `true` if `x` is finite and not `NaN`. Otherwise, returns `false`.

# Examples
```julia
julia> isnumber(5.0)
true

julia> isnumber(NaN)
false

julia> isnumber(-Inf)
false
```

See also: [`isnotnumber`](@ref)
"""
isnumber(x) = isfinite(x) && !isnan(x)

# 3. Function: fastextrema
# ------------------------

"""
    fastextrema(x) -> (mini, maxi)

Compute the minimum and maximum values of an input array `x` and return them
as a tuple.

`x` can be an array of `Real` numbers, `Gray` colorants, or multi-channel
colorants `Colorant{T,N}`, where `T` is a `Real` type. If `x` is an array of
`AbstractFloat` elements, values such as `NaN`, `Inf`, or `-Inf` are
automatically excluded from the computation. Additionally, `x` can be a `Skip`
object from the [Skipper.jl](https://github.com/JuliaAPlavin/Skipper.jl)
package, created using the `skip` or `keep` functions.

# Examples
```julia
julia> # Example with an array of real numbers
julia> data = [1.0, 2.0, 3.0, 4.0, 5.0]
julia> mini, maxi = fastextrema(data)
julia> println("Minimum: ", mini, ", Maximum: ", maxi)
Minimum: 1.0, Maximum: 5.0

julia> # Example with a multi-channel image
julia> img = rand(RGB{N0f8}, 10, 10) # Random RGB image
julia> mini, maxi = fastextrema(img)
julia> println("Minimum: ", mini, ", Maximum: ", maxi)
Minimum: RGB{N0f8}(0.004, 0.004, 0.0), Maximum: RGB{N0f8}(0.996, 0.992, 0.996)

julia> # Example with an 8-bit grayscale image, ignoring all values below 0.5
julia> img = rand(Gray{N0f8}, 10, 10)
julia> mini, maxi = skip(x -> x < 0.5, img) |> fastextrema
julia> println("Minimum: ", mini, ", Maximum: ", maxi)
Minimum: Gray{N0f8}(0.51), Maximum: Gray{N0f8}(0.984)
```

# Note
Microbenchmarks indicate that `fastextrema` is about twice as fast as
`Base.extrema` for floating-point numbers, but shows no significant benefit for
integers. The advantage of `fastextrema` lies in its support for Skipper.jl.
However, it is less versatile than `Base.extrema` as it lacks the `dims`
argument and does not support generic iterable collections. Despite this,
`fastextrema` should remain sufficient for image processing tasks.
"""
fastextrema

function fastextrema(x::GenericRealImageSkipper)
    mini = x |> eltype |> typemax
    maxi = x |> eltype |> typemin
    @inbounds for v in x
        if v < mini
            mini = v
        end
        if v > maxi
            maxi = v
        end
    end
    return mini, maxi
end

fastextrema(x::FloatImage) = fastextrema(skip(!isnumber, x))

function fastextrema(x::MultiChannelRealImage{T}) where T<:MultiChannelRealPixel
    minis = zeros(eltype(T), length(T))
    maxis = zeros(eltype(T), length(T))
    for (i, ch) in eachslice(channelview(x), dims=1) |> enumerate
        minis[i], maxis[i] = fastextrema(ch)
    end
    return T(minis...), T(maxis...)
end

function fastextrema(x::MultiChannelRealSkipper{P,A}) where {P,A}
    T = eltype(A)
    minis = zeros(eltype(T), length(T))
    maxis = zeros(eltype(T), length(T))
    @inbounds for v in x
        @inbounds for (i, chv) in channelview([v]) |> enumerate # not very clean, but it works
            if chv < minis[i]
                minis[i] = chv
            end
            if chv > maxis[i]
                maxis[i] = chv
            end
        end
    end
    return T(minis...), T(maxis...)
end

fastextrema(x) = error(
"""
The function `fastextrema` is not supported for type: $(typeof(x)). Currently
supported types include:
    - arrays of `Real` numbers
    - arrays of `Gray` colorants
    - arrays of `AbstractFloat` numbers, possibly containing `NaN`, `Inf`, or
      `-Inf` values
    - arrays of multi-channel `Colorant{T,N}`, where `T` is a `Real` type
    - `Skip` types for arrays of the above types, as defined by the `Skipper.jl`
      package

For more details, refer to the `fastextrema` documentation.
"""
)

# function approx_quantile fastquantile

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
