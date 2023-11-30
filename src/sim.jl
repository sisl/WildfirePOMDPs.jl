function ignite(s::WildfireState, x; copy=true)
	sp = copy ? deepcopy(s) : s
	if sp.fuel[x...] > 0
		@views sp.burning[x...] = true
	end
	return sp
end

function step(mdp::WildfireMDP, s::WildfireState, a::WildfireAction, rng::AbstractRNG=Random.GLOBAL_RNG)
    θ = mdp.wind_angle
    λ = mdp.p_ignite
    sp = deepcopy(s)
	if a.action_type == ResourceAllocation
		for aᵢ in a.locations
			if rand(rng) < mdp.p_extinguish
				@views sp.burning[aᵢ...] = false
				@views sp.fuel[aᵢ...] = 0
				# TODO: burnt?
			end
		end
	end
	for cell in findall(sp.burning)
		x = cell.I
		# roll dice to catch neighbor on fire
		for y in neighbors(sp, cell)
			if rand(rng) < p(sp, x, y; λ, θ)
				sp = ignite(sp, y; copy=false)
			end
		end
		# decrease fuel
		@views sp.fuel[x...] = clamp(sp.fuel[x...] - 1, 0, Inf)
		if sp.fuel[x...] ≤ 0
			@views sp.burning[x...] = false
			@views sp.burnt[x...] = true
		end
	end
	return sp
end

neighbors(sim, x::CartesianIndex) = neighbors(sim, x.I...)
function neighbors(s, i, j)
	N = []
	for y in [(i,j+1), (i,j-1), (i+1,j), (i-1,j)]
		if 1 ≤ y[1] ≤ s.dims[1] && 1 ≤ y[2] ≤ s.dims[2]
			push!(N, y)
		end
	end
	return N
end

function p(s, x, y; λ=0.5, θ=90)
	return 𝟙(y ∈ neighbors(s, x...)) * (1 - exp(-λ))
end

# TODO:
function θ(x,y)
	Δ = x .- y
	if Δ == (0, -1) # South
		return π
	elseif Δ == (1, 0) # East
		return π/2
	elseif Δ == (-1, 0) # West
		return 3π/2
	elseif Δ == (0, 1) # North
		return 0
	end
end
