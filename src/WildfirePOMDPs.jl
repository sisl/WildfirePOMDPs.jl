module WildfirePOMDPs

using Reexport
using Parameters
@reexport using POMDPs
@reexport using POMDPTools
@reexport using POMDPSimulators
@reexport using Plots
using Reel
using ColorSchemes
using Colors
using Distributions
using Random
using GeoStats

export
    WildfireMDP,
    set_population!,
    create_gif,
    render

include("utils.jl")
include("mdp.jl")
include("sim.jl")
include("mixed_color_gradients.jl")
include("plotting.jl")
include("env.jl")

end # module WildfirePOMDPs
