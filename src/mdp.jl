global DEFAULT_MAX_FUEL = 40

@with_kw struct WildfireState # State definition
    dims::Tuple
    burning::Matrix{Union{<:Bool,<:Real}} = falses(dims...)
	max_fuel::Real = DEFAULT_MAX_FUEL
	terrain = generate_terrain(dims; max_fuel)
    fuel::Matrix{Real} = deepcopy(terrain)
    burnt::Matrix{Union{<:Bool,<:Real}} = falses(dims...)
end
WildfireState(dims) = WildfireState(; dims)

@enum WildfireActionType NoAction ResourceAllocation AerialObservation

@with_kw struct WildfireAction
	action_type::WildfireActionType = NoAction
	locations::Union{Missing, Vector{Tuple{Int,Int}}} = missing
end

@with_kw struct WildfireMDP <: MDP{WildfireState, WildfireAction}
	dims = (100,100)               # grid dimensions
	walls = falses(dims...)        # fire blocking walls
    population = falses(dims...)   # populated areas
	init_fire_location = (dims[1]÷2, dims[2]÷2) # location of the initial fire
	init_fire_distr = Product([Categorical(dims[1]), Categorical(dims[2])]) # distribution to sample initial ignition cells
	init_ignition_steps = 40       # time to let initial fire spread
	resource_action_size = (2, 20) # size of the water resource drops
	resource_actions = all_actions(dims, resource_action_size, ResourceAllocation) # all water drop actions
	allow_non_burning_actions = false # allow actions to be placed on non-burning cells
	max_fuel = DEFAULT_MAX_FUEL    # maximum fuel
	burning_cost = -1              # cost of each burning cell
    population_cost = -1000        # cost of population damage
	p_extinguish = 0.95            # probability of each water placement extinguishing the fire
	num_water_drops = 10           # number of water placements per step
	discount = 0.99                # MDP discount
    wind_angle = 90                # direction of wind
    p_ignite = 0.25                # probability to ignite neighbor
end

function set_population!(mdp, cells)
    for (x,y) in cells
        mdp.population[x,y] = true
    end
end

const DIRECTIONS = [
	(0,1), (1,0), (0,-1), (-1,0), # Cardinal directions
	(1,1), (-1,1), (1,-1), (-1,-1) # Diagonals
]

function all_actions(dims, action_size, action_type)
	A = WildfireAction[]
	for actsize in (action_size, reverse(action_size))
		Xs = (0:actsize[1]:dims[1]) .+ 1
		Ys = (0:actsize[2]:dims[2]) .+ 1
		for i in 1:length(Xs)-1
			for j in 1:length(Ys)-1
				water_block = Tuple{Int,Int}[]
				for x in Xs[i]:Xs[i+1]-1
					for y in Ys[j]:Ys[j+1]-1
						push!(water_block, (x,y))
					end
				end
				a = WildfireAction(action_type, water_block)
				push!(A, a)
			end
		end
	end
	return A
end

POMDPs.actions(mdp::WildfireMDP) = mdp.resource_actions

function POMDPs.actions(mdp::WildfireMDP, s::WildfireState) # Action−space
	burning_cells = map(ci->ci.I, findall(s.burning))
	if isempty(burning_cells)
		return [WildfireAction()]
	else
		A = actions(mdp)
		if mdp.allow_non_burning_actions
			return A
		else
			legal_actions = WildfireAction[]
			for a in A
				for fire in burning_cells
					if fire ∈ a.locations
						push!(legal_actions, a)
					end
				end
			end
			return legal_actions
		end
	end
end

function POMDPs.reward(mdp::WildfireMDP,
					   s::WildfireState,
					   a::WildfireAction=WildfireAction())
	return sum(b * (mdp.burning_cost + p * mdp.population_cost) for (b,p) in zip(s.burning, mdp.population))
end

POMDPs.discount(mdp::WildfireMDP) = mdp.discount
POMDPs.isterminal(mdp::WildfireMDP, s::WildfireState) = all(s.burning .== false)

function POMDPs.transition(mdp::WildfireMDP,
		s::WildfireState,
		a::WildfireAction,
		rng::AbstractRNG=Random.GLOBAL_RNG)
	return Deterministic(step(mdp, s, a, rng)) # step is already stochastic
end

function POMDPs.gen(mdp::WildfireMDP,
					s::WildfireState,
					a::WildfireAction,
					rng::AbstractRNG=Random.GLOBAL_RNG)

	sp = rand(transition(mdp, s, a, rng))
	r = reward(mdp, s, a)
	return (; sp, r)
end

struct HierarchicalFireSampler
	mdp::WildfireMDP
end

function Base.rand(rng::AbstractRNG, hfs::HierarchicalFireSampler)
	mdp = hfs.mdp
	dims = mdp.dims
	max_fuel = mdp.max_fuel

	burning = falses(dims...)
	burning[mdp.init_fire_location...] = true

	s = WildfireState(; dims, max_fuel, burning)
	a = WildfireAction()
	for t in 1:mdp.init_ignition_steps
		s = step(mdp, s, a, rng)
	end
	return s
end

function POMDPs.initialstate(mdp::WildfireMDP)
	return HierarchicalFireSampler(mdp)
end

isfailure(mdp::MDP, h::SimHistory) = any(isfailure(mdp, step.s) for step in h)
function isfailure(mdp::WildfireMDP, s::WildfireState)
	return any(𝟙.(mdp.population) .* 𝟙.(s.burning) .== 1) || any(𝟙.(mdp.population) .* 𝟙.(s.burnt) .== 1)
end
