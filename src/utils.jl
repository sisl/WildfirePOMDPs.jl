𝟙(b::Bool) = b ? 1 : 0
𝟙(b::Real) = b > 1 ? error("𝟙(b) should input a value of b ∈ [0, 1]") : b
𝟙(b::Bool, t, f) = b ? t : f
𝟙(b::Real, t, f) = b > 1 ? t : f

normalize01(X) = (X .- minimum(X)) / (maximum(X) - minimum(X))

function normalize_fuel(M, min_fuel, max_fuel)
	return Float64.(round.(Int, max_fuel * normalize01(M))) .+ min_fuel
end