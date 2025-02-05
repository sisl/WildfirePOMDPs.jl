module WildfirePOMDPs

using Reexport
@reexport using Distributions
@reexport using ParticleFilters
@reexport using Plots
@reexport using POMDPs
@reexport using POMDPTools
@reexport using Random
@reexport using Statistics
using Colors
using ColorSchemes
using GeoStats
using LinearAlgebra
using Parameters
using Reel

export
    WildfireMDP,
    WildfireState,
    WildfireAction,
    WildfirePOMDP,
    WildfireObservation,
    HierarchicalFireSampler,
    NoAction,
    ResourceAllocation,
    AerialObservation,
    set_population!,
    isfailure,
    create_gif,
    plot_fire,
    render,
    𝟙

include("utils.jl")
# include("fire_sampler.jl")
include("mdp.jl")
include("pomdp.jl")
include("sim.jl")
include("mixed_color_gradients.jl")
include("plotting.jl")
include("env.jl")

end # module WildfirePOMDPs
