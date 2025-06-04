using BaseZz
using Test

using ImageCore, ImageBase, ImageAxes, ImageMetadata, Skipper

using Aqua
#Aqua.test_all(BaseZz; stale_deps=(;ignore=[:ImageAxes, :ImageMetadata, :BaseZz]))
    #test_ambiguities([BaseZz])
    #=
    test_unbound_args(testtarget)
    test_undefined_exports(testtarget)
    test_project_extras(testtarget)
    test_stale_deps(testtarget)
    test_deps_compat(testtarget)
    test_piracies(testtarget)
    test_persistent_tasks(testtarget)
    test_undocumented_names(testtarget)
@testset "Aqua.jl" begin
  Aqua.test_all(
    BaseZz;
    ambiguities=false,      # TODO: fix ambiguities
    piracies=false          # TODO: fix piracy
  )
end=#
@testset "aqua unbound_args" begin
    Aqua.test_unbound_args(BaseZz)
end
@testset "aqua deps compat" begin
    Aqua.test_deps_compat(BaseZz)
end
@testset "aqua undefined exports" begin
    Aqua.test_undefined_exports(BaseZz)
end
@testset "aqua piracy" begin
    Aqua.test_piracies(BaseZz)
end
@testset "aqua project extras" begin
    Aqua.test_project_extras(BaseZz)
end
@testset "aqua stale deps" begin
    Aqua.test_stale_deps(BaseZz)
end
@testset "aqua test ambiguities" begin
    Aqua.test_ambiguities([BaseZz, Core, Base])
end

@testset "BaseZz.jl" begin
    include("utils.jl")
end
