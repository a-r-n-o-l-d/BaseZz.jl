module BaseZz

using Reexport
@reexport using ImageCore, ImageBase, ImageAxes, ImageMetadata, Skipper
# ColorTypes, Colors, FixedPointNumber
#using Skipper
using .Threads: @threads, nthreads, threadid

export SingleThread, MultiThreads

struct SingleThread end
struct MultiThreads end

# To do : histogram multithrede pour grosses images, quantile approx par histogram pour rapidite vision

export isnumber, fastextrema, hbox, bbox

include("utils.jl")

#=
function unsafe_extrema(x) # benchmark avec Skipper pour abstract float
    a = b = first(x)
    for v in x
        v > b && (b = v)
        v < a && (a = v)
    end
    a, b
end

function unsafe_minimum(x) # benchmark avec Skipper pour abstract float
  a = first(x)
  for v in x
      v < a && (a = v)
  end
  a
end

function unsafe_maximum(x) # benchmark avec Skipper pour abstract float
  b = first(x)
  for v in x
      v > b && (b = v)
  end
  b
end
=#

# Rectangular range




# BoundingBox
function bbox(A, b = 0)
  R = CartesianIndices(A)
  Imin, Imax = last(R), first(R)
  for I ∈ R
      if A[I]
          Imin = min(Imin, I)
          Imax = max(Imax, I)
      end
  end
  hbox(max(Imin - b, first(R)), min(Imax + b, last(R)))
end

end
