using BaseZz
using Documenter

DocMeta.setdocmeta!(BaseZz, :DocTestSetup, :(using BaseZz); recursive=true)

makedocs(;
    modules=[BaseZz],
    authors="Arnold",
    sitename="BaseZz.jl",
    format=Documenter.HTML(;
        canonical="https://a-r-n-o-l-d.github.io/BaseZz.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/a-r-n-o-l-d/BaseZz.jl",
    devbranch="main",
)
