function generate_elevation(dims; seed=0)
	Random.seed!(seed)
	𝒢 = CartesianGrid(dims...)
	𝒫 = SimulationProblem(𝒢, :elevation => Float64, 1)
	S = LUGS(:elevation => (variogram=GaussianVariogram(range=25),))
	solution = GeoStats.solve(𝒫, S)
	return Matrix(reshape(solution.reals.elevation[1], solution.domain.topology.dims)')
end

function generate_terrain(dims; max_fuel=40, seed=0)
	Random.seed!(seed)
	𝒢ₜ = CartesianGrid(dims...)
	𝒫ₜ = SimulationProblem(𝒢ₜ, :terrain => Float64, 1)
	Sₜ = LUGS(:terrain => (variogram=GaussianVariogram(range=25),))
	solution = GeoStats.solve(𝒫ₜ, Sₜ)
	terrain = Matrix(reshape(solution.reals.terrain[1], dims)')

	# Normalize and round to integer
	return Float64.(round.(Int, max_fuel * normalize01(terrain)))
end
