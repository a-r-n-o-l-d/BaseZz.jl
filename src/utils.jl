#=
# Deliberately not export these constants to enable extensibility for downstream packages
const NumberLike = Union{Number,AbstractGray}
const Pixel = Union{Number,Colorant}
const GenericGrayImage{T<:NumberLike,N} = AbstractArray{T,N}
const GenericImage{T<:Pixel,N} = AbstractArray{T,N}
=#

# NOTE: remove Generic?? to have shorter names

const RealPixel{T<:Real} = Union{T,AbstractGray{T}}
# Complex int...?
const FloatPixel{T<:AbstractFloat} = Union{T,AbstractGray{T}} #,<:Color{AbstractFloat,1}
#const GenericRealIterable = Union{AbstractArray{RealPixel}}
const RealImage{T<:RealPixel,N} = AbstractArray{T,N}
const FloatImage{T<:FloatPixel,N} = AbstractArray{T,N}
#=
RealArraySkipper{P} = Skipper.Skip{P,GenericRealImage}
RealArraySkipper2{P} = Skipper.Skip{P,<:GenericRealImage}
RealArraySkipper3{P,A<:GenericRealImage} = Skipper.Skip{P,A}
=#
const RealSkipper{P,A<:RealImage} = Skipper.Skip{P,A}
const GenericRealImageSkipper = Union{RealImage,RealSkipper}

const MultiChannelRealPixel{T<:Real,N} = Color{T,N}
const MultiChannelRealImage{T<:MultiChannelRealPixel,N} = AbstractArray{T,N}

const MultiChannelRealSkipper{P,A<:MultiChannelRealImage} = Skipper.Skip{P,A}
#const GenericMultiChannelRealImageSkipper{T<:MultiChannelRealPixel} = Union{GenericMultiChannelRealImage{T},<:GenericMultiChannelRealSkipper{P,GenericMultiChannelRealImage{T}}} where P

#=
const XtRealArray = Union{
    AbstractArray{<:Real},
    AbstractArray{<:Color{<:Real,1}},
    Skipper.Skip{<:Any,<:AbstractArray{<:Real}},
    Skipper.Skip{<:Any,<:AbstractArray{<:Color{<:Real,1}}}
}

const XtFloatArray = Union{
    AbstractArray{<:AbstractFloat},
    AbstractArray{<:Color{<:AbstractFloat,1}}
}

const XtN0f8Array = Union{
    AbstractArray{<:N0f8},
    AbstractArray{<:Color{<:N0f8,1}}
}
=#

isnotnumber(x) = !isfinite(x) || isnan(x) || ismissing(x)
isnumber(x) = !isnotnumber(x)

# as_finite(x) = skip(isnan || !isfinite, x)

"""
    fastextrema(x) -> (mini, maxi)

Compute the minimum and maximum values of an input array `x` and return them
as a tuple.

`x` can be an array of `Real` numbers, `Gray` colorants, or multi-channel
colorants `Colorant{T,N}`, where `T` is a `Real` type. If `x` is an array of
`AbstractFloat` elements, values such as `NaN`, `missing`, `Inf`, or `-Inf` are
automatically excluded from the computation. Additionally, `x` can be a `Skip`
object from the [Skipper.jl](https://github.com/JuliaAPlavin/Skipper.jl)
package, created using the `skip` or `keep` functions.

# Examples
```julia
# Example with an array of real numbers
data = [1.0, 2.0, 3.0, 4.0, 5.0]
mini, maxi = fastextrema(data)
println("Minimum: ", mini, ", Maximum: ", maxi)

# Example with a multi-channel image
img = rand(RGB, 10, 10) # Random RGB image
mini, maxi = fastextrema(img)
println("Minimum: ", mini, ", Maximum: ", maxi)

# Example with an 8-bit grayscale image, ignoring all values below 0.5
img = rand(Gray{N0f8}, 10, 10)
mini, maxi = skip(x -> x < 0.5, img) |> fastextrema
println("Minimum: ", mini, ", Maximum: ", maxi)
```

# Note
Microbenchmarks indicate that fastextrema is about twice as fast as
Base.extrema for floating-point numbers, but shows no significant benefit for
integers. The advantage of fastextrema lies in its support for Skipper.jl.
However, it is less versatile than Base.extrema as it lacks the dims
argument and does not support generic iterable collections. Despite this,
fastextrema remains sufficient for image processing tasks.
"""
fastextrema

# 2 times faster than Base.extrema for float thanks to Skipper.jl (no big benefit for Int), but maybe unsafe
# a little faster than minimum or maximum for float, two times faster for Int (not sure)
# To do: design clean microbenchmarks (on other ubuntu machine)
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

fastextrema(x::FloatImage) = fastextrema(skip(isnotnumber, x)) #where T<:AbstractFloat

function fastextrema(x::MultiChannelRealImage{T}) where T<:MultiChannelRealPixel
    #extvals = [(zero(eltype(T)), zero(eltype(T))) for _ in 1:length(T)]
    minis = zeros(eltype(T), length(T))
    maxis = zeros(eltype(T), length(T))
    for (i, ch) in eachslice(channelview(x), dims=1) |> enumerate
        minis[i], maxis[i] = fastextrema(ch)
    end
    return T(minis...), T(maxis...) #extvals
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
    Function `fastextrema` is not supported for type: $(typeof(x)). Currently supported types are:
        - arrays of `Real` numbers
        - arrays of `Gray` colorants
        - arrays of `AbstractFloat` numbers with eventually `NaN`, `missing`, `Inf` or `-Inf` values
        - arrays of multi-channels `Colorant{T,N}` where `T` is a `Real` type
        - a `Skip` type for arrays of above types defined by package `Skipper.jl`
    See `fastextrema` documentation for more details.
    """
)

# function approx_quantile

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
