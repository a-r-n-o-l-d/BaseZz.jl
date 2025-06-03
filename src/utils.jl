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
const GenericRealImage{T<:RealPixel,N} = AbstractArray{T,N}
const GenericFloatImage{T<:FloatPixel,N} = AbstractArray{T,N}
#=
RealArraySkipper{P} = Skipper.Skip{P,GenericRealImage}
RealArraySkipper2{P} = Skipper.Skip{P,<:GenericRealImage}
RealArraySkipper3{P,A<:GenericRealImage} = Skipper.Skip{P,A}
=#
const GenericRealSkipper{P,A<:GenericRealImage} = Skipper.Skip{P,A}
const GenericRealImageSkipper = Union{GenericRealImage,GenericRealSkipper}

const MultiChannelRealPixel{T<:Real,N} = Color{T,N}
const GenericMultiChannelRealImage{T<:MultiChannelRealPixel,N} = AbstractArray{T,N}

const GenericMultiChannelRealSkipper{P,A<:GenericMultiChannelRealImage} = Skipper.Skip{P,A}
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

fastextrema(x::GenericFloatImage) = fastextrema(skip(isnotnumber, x)) #where T<:AbstractFloat

function fastextrema(x::GenericMultiChannelRealImage{T}) where T<:MultiChannelRealPixel
    #extvals = [(zero(eltype(T)), zero(eltype(T))) for _ in 1:length(T)]
    minis = zeros(eltype(T), length(T))
    maxis = zeros(eltype(T), length(T))
    for (i, ch) in eachslice(channelview(x), dims=1) |> enumerate
        minis[i], maxis[i] = fastextrema(ch)
    end
    return T(minis...), T(maxis...) #extvals
end

function fastextrema(x::GenericMultiChannelRealSkipper{P,A}) where {P,A}
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
        - a `Skip` type of above types defined by package `Skipper.jl`
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
