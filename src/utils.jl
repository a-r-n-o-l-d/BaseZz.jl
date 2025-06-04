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
## Example with an array of real numbers
```julia
julia> data = [1.0, 2.0, 3.0, 4.0, 5.0]
julia> mini, maxi = fastextrema(data)
julia> println("Minimum: ", mini, ", Maximum: ", maxi)
Minimum: 1.0, Maximum: 5.0
```
## Example with a multi-channel image
```julia
julia> img = rand(RGB{N0f8}, 10, 10)
julia> mini, maxi = fastextrema(img)
julia> println("Minimum: ", mini, ", Maximum: ", maxi)
Minimum: RGB{N0f8}(0.004, 0.004, 0.0), Maximum: RGB{N0f8}(0.996, 0.992, 0.996)
```
## Example with an 8-bit grayscale image, ignoring all values below 0.5
```julia
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


# 4. Function: hbox
# -----------------

"""
    hbox(I, J; stride=one(I)) -> CI

Construct a `CartesianIndices` range defining a hyperrectangular box from
`CartesianIndex` `I` to `CartesianIndex` `J` with a specified `stride`. The
resulting range `CI` can be used to subset a multidimensional array.

# Examples
## Define starting point `I` and ending point `J`
```julia
julia> I = CartesianIndex(3, 3)
CartesianIndex(3, 3)

julia> J = CartesianIndex(7, 7)
CartesianIndex(7, 7)
```
## Create two boxes, with and without stride
```julia
julia> b1 = hbox(I, J)
CartesianIndices((3:1:7, 3:1:7))

julia> b2 = hbox(I, J, stride=CartesianIndex(2, 2))
CartesianIndices((3:2:7, 3:2:7))
```
## Example of subsetting an array as copy or as view
```julia
julia> A = reshape(1:64, 8, 8)
8×8 reshape(::UnitRange{Int64}, 8, 8) with eltype Int64:
 1   9  17  25  33  41  49  57
 2  10  18  26  34  42  50  58
 3  11  19  27  35  43  51  59
 4  12  20  28  36  44  52  60
 5  13  21  29  37  45  53  61
 6  14  22  30  38  46  54  62
 7  15  23  31  39  47  55  63
 8  16  24  32  40  48  56  64

julia> A[b1]
5×5 Matrix{Int64}:
 19  27  35  43  51
 20  28  36  44  52
 21  29  37  45  53
 22  30  38  46  54
 23  31  39  47  55

julia> A[b2]
3×3 Matrix{Int64}:
 19  35  51
 21  37  53
 23  39  55

 julia> view(A, b1)
5×5 view(reshape(::UnitRange{Int64}, 8, 8), 3:1:7, 3:1:7) with eltype Int64:
 19  27  35  43  51
 20  28  36  44  52
 21  29  37  45  53
 22  30  38  46  54
 23  31  39  47  55

julia> view(A, b2)
3×3 view(reshape(::UnitRange{Int64}, 8, 8), 3:2:7, 3:2:7) with eltype Int64:
 19  35  51
 21  37  53
 23  39  55
```
"""
function hbox(I::T, J::T; stride=oneunit(I)) where T<:CartesianIndex # stride Int aussi
    ind = []
    gp = @. Tuple((I, stride, J))
    for (i, s, j) ∈ zip(gp...)
        push!(ind, i:s:j)
    end
    return Tuple(ind) |> CartesianIndices
end


# 5. Function: bbox
# -----------------

"""
    bbox(A; margin=CartesianIndex(zeros(Int, ndims(A))...)) -> CI

Compute the bounding box of `true` elements in array `A` and return it as a
`CartesianIndices` range.

This function scans the boolean array `A` to find the smallest hyperrectangle
that contains all the `true` elements. The resulting bounding box can be
expanded by a specified `margin` in all directions. The `margin` is constrained
to the dimensions of the array `A`.

# Example
```julia
julia> A = [
    false false true false false;
    false true  true false false;
    false false true false false
]
3×5 Matrix{Bool}:
 0  0  1  0  0
 0  1  1  0  0
 0  0  1  0  0

julia> b1 = bbox(A)
CartesianIndices((2:3, 2:3))

julia> b2 = bbox(A, margin=CartesianIndex(1,1))
CartesianIndices((1:3, 1:3))

julia> A[b1]
3×2 Matrix{Bool}:
 0  1
 1  1
 0  1

julia> A[b2]
3×4 Matrix{Bool}:
 0  0  1  0
 0  1  1  0
 0  0  1  0
```
"""
function bbox(A; margin=CartesianIndex(zeros(Int, ndims(A))...))
    if any(A)
        R = CartesianIndices(A)
        Imin, Imax = last(R), first(R)
        for I ∈ R
            if A[I]
                Imin = min(Imin, I)
                Imax = max(Imax, I)
            end
        end
        return hbox(max(Imin - margin, first(R)), min(Imax + margin, last(R)))
    end
    return CartesianIndices(A)
end

#hbox(i, j; stride=oneunit(CartesianIndex(i...))) = hbox(CartesianIndex(i...), CartesianIndex(j...), stride=stride)

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
