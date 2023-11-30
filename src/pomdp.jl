const WildfireObservation = Any

@with_kw struct WildfirePOMDP <: POMDP{WildfireState, WildfireAction, WildfireObservation}
	mdp::WildfireMDP
	obs_action_size = (10, 100) # size of the observation actions
	obs_actions = all_actions(mdp.dims, obs_action_size, AerialObservation) # all observation actions
    σ_abc::Real = 0.1 # Standard deviation for approximate Bayesian computation (ABC) particle filter
end

WildfirePOMDP(mdp::WildfireMDP) = WildfirePOMDP(; mdp)

POMDPs.initialstate(pomdp::WildfirePOMDP) = initialstate(pomdp.mdp)

# ! TODO: action(pomdp, b::WildfireBelief)
POMDPs.actions(pomdp::WildfirePOMDP) = vcat(pomdp.mdp.resource_actions, pomdp.obs_actions)
function POMDPs.actions(pomdp::WildfirePOMDP, s::WildfireState)
    resource_actions = actions(pomdp.mdp, s) # Water drop actions
    return vcat(resource_actions, pomdp.obs_actions)
end

# ! TODO: reward(pomdp, b::WildfireBelief)
function POMDPs.reward(pomdp::WildfirePOMDP,
                       s::WildfireState,
                       a::WildfireAction=WildfireAction())
    return reward(pomdp.mdp, s, a)
end

POMDPs.discount(pomdp::WildfirePOMDP) = discount(pomdp.mdp)
POMDPs.isterminal(pomdp::WildfirePOMDP, s::WildfireState) = isterminal(pomdp.mdp, s)

function POMDPs.transition(pomdp::WildfirePOMDP,
		s::WildfireState,
		a::WildfireAction,
		rng::AbstractRNG=Random.GLOBAL_RNG)
	return Deterministic(step(pomdp.mdp, s, a, rng)) # step is already stochastic
end

function POMDPs.gen(pomdp::WildfirePOMDP,
    s::WildfireState,
    a::WildfireAction,
    rng::AbstractRNG=Random.GLOBAL_RNG)
    
    sp = rand(transition(pomdp, s, a, rng))
    r = reward(pomdp.mdp, s, a)
    o = observation(pomdp, a, sp)
    return (; sp, r, o)
end

# Function for handling vector of actions (and therefore vector of observations)
# function POMDPTools.obs_weight(pomdp::WildfirePOMDP, s, a::Vector{Tuple{Int64, Int64}}, sp, o::Vector{Float64})
#     w = 1.0
#     for (a_i, o_i) in zip(a, o)
#         w *= obs_weight(pomdp, s, a_i, sp, o_i)
#     end
#     return w
# end

function POMDPTools.obs_weight(pomdp::WildfirePOMDP, s::WildfireState, a::WildfireAction, sp::WildfireState, o::WildfireObservation)
    if isterminal(pomdp, s) || a.action_type == NoAction
        w = Float64(isinf(o))
    else
        burning = map(location->s.burning[location...], a.locations)
        # burning = map(location->𝟙(s.burning[location...]), a.locations)
        # m = length(burning)
        # gaussians_burning = [Normal(b, pomdp.σ_abc) for b in burning]
        # # mv_burning = MvNormal(burning, diagm(0=>fill(pomdp.σ_abc, m)))
        o_burning = o[:,1]

        w = sum(burning .&& o_burning)

        # fuel = map(location->s.fuel[location...], a.locations)
        # gaussians_fuel = [Normal(f, pomdp.σ_abc) for f in fuel]
        # # mv_fuel = MvNormal(fuel, diagm(0=>fill(pomdp.σ_abc, m)))
        # o_fuel = o[:,2]

        # w = 1
        # w = prod(pdf(gburning, ob) * pdf(gfuel, of) for (gburning, ob, gfuel, of) in zip(gaussians_burning, o_burning, gaussians_fuel, o_fuel))
        # w = exp(logpdf(mv_burning, o_burning) + logpdf(mv_fuel, o_fuel))
    end
    return w
end

function POMDPs.observation(pomdp::WildfirePOMDP, a::WildfireAction, s::WildfireState)
    if isterminal(pomdp, s) || a.action_type == NoAction
        o = -Inf32
    else
        o = hcat(
            map(location->s.burning[location...], a.locations),
            map(location->s.fuel[location...], a.locations)
        )
    end
    return o
end


function Base.:+(s1::WildfireState, s2::WildfireState)
	@assert s1.dims == s2.dims
	@assert s1.max_fuel == s2.max_fuel
    dims = s1.dims
    max_fuel = s1.max_fuel
    burning = s1.burning + s2.burning
    fuel = s1.fuel + s2.fuel
    burnt = s1.burnt + s2.burnt
    terrain = s1.terrain + s2.terrain
	return WildfireState(; dims, burning, max_fuel, fuel, burnt, terrain)
end

function Base.:/(s::WildfireState, d::Int)
    dims = s.dims
    burning = s.burning / d
    max_fuel = s.max_fuel / d
    fuel = s.fuel / d
    burnt = s.burnt / d
    terrain = s.terrain / d
	return WildfireState(; dims, burning, max_fuel, fuel, burnt, terrain)
end

Statistics.std(b::ParticleCollection{<:WildfireState}) = uncertainty(b, std)
Statistics.var(b::ParticleCollection{<:WildfireState}) = uncertainty(b, var)
function uncertainty(b::ParticleCollection{<:WildfireState}, f=std)
	S = particles(b)
	dims = S[1].dims
	burnings = [s.burning for s in S]
	fuels = [s.fuel for s in S]
	burnts = [s.burnt for s in S]
	return WildfireState(dims=dims, burning=f(burnings), fuel=f(fuels), burnt=f(burnts))
end