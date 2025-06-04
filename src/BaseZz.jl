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

end
