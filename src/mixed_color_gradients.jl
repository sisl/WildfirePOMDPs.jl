@with_kw mutable struct MixedColorGradient
	continuous
	discrete
	condition::Function
	nancolor::Any = invisible() # not working...
end

function Base.get(mcg::MixedColorGradient, v::AbstractArray, rangescale = (0.0, 1.0))
	rangescale === :extrema && (rangescale = extrema(v))
    map(x -> get(mcg, x, rangescale), v)
end

function Base.get(mcg::MixedColorGradient, x::AbstractFloat, rangescale = (0.0, 1.0))
	isfinite(x) || return mcg.nancolor
    rangescale = PlotUtils.get_rangescale(rangescale)
    allunique(rangescale) || return first(mcg.discrete.colors)
    x = clamp(x, rangescale...)
    if rangescale != (0.0, 1.0)
        x = ColorSchemes.remap(x, rangescale..., 0, 1)
    end
    PlotUtils.sample_color(mcg, x)  # specialize for x (boxing issues ?)
end

function PlotUtils.sample_color(mcg::MixedColorGradient, x::AbstractFloat)
	if mcg.condition(x)
		cg = mcg.discrete
	else
		cg = mcg.continuous
	end
	c, v = cg.colors, cg.values
    if (index = findfirst(==(x), v)) === nothing
        nm1 = length(v) - 1
        i = min(nm1, findlast(<(x), v))
        r = (x - v[i]) / (v[i + 1] - v[i])
        index = (i + r - 1) / nm1
    end
    return c[index]
end

PlotUtils.plot_color(mcg::MixedColorGradient) = mcg
Base.getindex(mcg::MixedColorGradient, x::Union{AbstractFloat,AbstractVector{<:AbstractFloat}}) = get(mcg, x)
