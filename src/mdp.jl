@with_kw struct WildfireState # State definition
    dims::Tuple
    burning::Matrix{Bool} = falses(dims...)
    fuel::Matrix{Int} = 40ones(dims...)
    burnt::Matrix{Bool} = falses(dims...)
end
WildfireState(dims) = WildfireState(; dims)

const WildfireAction = Union{Vector{Tuple{Int,Int}}, Missing}

@with_kw struct WildfireMDP <: MDP{WildfireState, WildfireAction}
	dims = (30,30)
	walls = falses(dims...)
    population = falses(dims...)
	num_initial_fires = 10 # number of initial fire locations
	init_fire_distr = Product([Categorical(dims[1]), Categorical(dims[2])])
	max_fuel = 40         # maximum fuel
	burning_cost = -1     # cost of each burning cell
    # population_cost = -1000 # cost of population damage
	p_extinguish = 0.95   # probability of each water placement extinguishing the fire
	num_water_drops = 10  # number of water placements per step
	discount = 0.99       # MDP discount
    wind_angle = 90       # direction of wind
    p_ignite = 0.5        # probability to ignite neighbor
	terrain = generate_terrain(dims; max_fuel)
	elevation = generate_elevation(dims)
end

function set_population!(mdp, cells)
    for (x,y) in cells
        mdp.population[x,y] = true
    end
end

const DIRECTIONS = [
	(0,1),
	(1,0),
	(0,-1),
	(-1,0),
	(1,1),
	(-1,1),
	(1,-1),
	(-1,-1)
]

function POMDPs.actions(mdp::WildfireMDP, s::WildfireState) # Action−space
	A = map(ci->ci.I, findall(s.burning))
	if isempty(A)
		return [missing]
	else
		placements = []
		for xy in A
			for dir in DIRECTIONS
				place = [xy]
				for i in 2:mdp.num_water_drops
					xy′ = place[i-1] .+ dir
					if 1 ≤ xy′[1] ≤ mdp.dims[1] && 1 ≤ xy′[2] ≤ mdp.dims[2]
						push!(place, xy′)
					else
						break
					end
				end
				push!(placements, place)
			end
		end
		return placements
	end
end

function POMDPs.reward(mdp::WildfireMDP,
					   s::WildfireState,
					   a::WildfireAction=missing)
    population_cost = -1000 # TODO. Parameterize
	return sum(b * (mdp.burning_cost + p * population_cost) for (b,p) in zip(s.burning, mdp.population))
end

POMDPs.discount(mdp::WildfireMDP) = mdp.discount
POMDPs.isterminal(mdp::WildfireMDP, s::WildfireState) = all(s.burning .== false)

function POMDPs.gen(mdp::WildfireMDP,
					s::WildfireState,
					a::WildfireAction,
					rng::AbstractRNG=Random.GLOBAL_RNG)

	r = reward(mdp, s, a)
	sp = step(mdp, s, a)
	return (; sp=sp, r=r)
    # return (; sp=sp, o=o, r=r)
end

function POMDPs.initialstate(mdp::WildfireMDP)
	fuel = deepcopy(mdp.terrain)
	# TODO: wall locations
	s = WildfireState(dims=mdp.dims, fuel=fuel)
    init_fires = []
    for i in 1:mdp.num_initial_fires
        fire = rand(mdp.init_fire_distr)
        while mdp.population[fire...] # rejection sampling to avoid initial fire on population
            fire = rand(mdp.init_fire_distr)
        end
        push!(init_fires, fire)
    end
	for init_fire in init_fires
		s = ignite(s, init_fire)
	end
	return Deterministic(s) # TODO: distribution over initial fires.
end
