function generate_elevation(dims; seed=missing, use_geostats=false, rng::AbstractRNG=Random.GLOBAL_RNG)
	# TODO: Elevation is not included in the dynamics.
	!ismissing(seed) && Random.seed!(seed)
	𝒢 = CartesianGrid(dims...)
	𝒫 = SimulationProblem(𝒢, :elevation => Float64, 1)
	S = LUGS(:elevation => (variogram=GaussianVariogram(range=25.0),))
	solution = GeoStats.solve(𝒫, S)
	return Matrix(reshape(solution.reals.elevation[1], solution.domain.dims)')
end

function generate_terrain(dims; min_fuel=10, max_fuel=40, n_mixtures=10, dimscale=3, seed=missing, use_geostats=false, rng::AbstractRNG=Random.GLOBAL_RNG)
	!ismissing(seed) && Random.seed!(seed)
	if use_geostats
		𝒢ₜ = CartesianGrid(dims...)
		𝒫ₜ = SimulationProblem(𝒢ₜ, :terrain => Float64, 1)
		Sₜ = LUGS(:terrain => (variogram=GaussianVariogram(range=25.0),))
		solution = GeoStats.solve(𝒫ₜ, Sₜ)
		terrain = Matrix(reshape(solution.reals.terrain[1], dims)')
	else
		mvs = Vector{MvNormal}(undef, n_mixtures)
		center_distribution = Product([Distributions.Categorical(dims[1]), Distributions.Categorical(dims[2])])
		for i in eachindex(mvs)
			μ = rand(rng, center_distribution)
			m = length(μ)
			Σ = Matrix(Hermitian(dimscale*(rand(rng,m,m) + dims[1]*I)))
			mvs[i] = MvNormal(μ, Σ)
		end
		terrain_mm = MixtureModel(mvs)
		terrain = [pdf(terrain_mm, [x,y]) for y in 1:dims[2], x in 1:dims[1]]
	end

	# Normalize and round to integer
	return normalize_fuel(terrain, min_fuel, max_fuel)
end
