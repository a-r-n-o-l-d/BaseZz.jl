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


end
