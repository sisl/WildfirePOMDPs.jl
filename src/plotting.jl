const PLOTTING_DEFAULTS = (fontfamily="Computer Modern", framestyle=:box) # LaTex-style plots
default(; PLOTTING_DEFAULTS...)

const CMAP_FIRE = ColorScheme([
	RGB([0.2, 0.2, 0.2]...),
	RGB([184,17,0]/255...),
	RGB([246,123,13]/255...),
	RGB([242,206,53]/255...),
])

const CMAP_ELEVATION = ColorScheme([
	RGB([173,200,139]/255...),
	RGB([254,254,207]/255...),
	RGB([241,159,98]/255...)
])

const CMAP_TERRAIN = :YlGn

const MCG = MixedColorGradient(
		cgrad(CMAP_FIRE.colors),
		cgrad(fill(:white, 2)),
		y->y == 0,
		RGB([0.2, 0.2, 0.2]...))

function render(mdp::WildfireMDP, s::WildfireState, a::WildfireAction; kwargs...)
    default(; PLOTTING_DEFAULTS...)
	pfire = plot_fire(mdp, s, a; kwargs...)
	pfuel = plot_fuel(s.fuel; max_fuel=mdp.max_fuel)
	return plot(pfire, pfuel, size=(600,250))
end

# ! TODO: WildfirePOMDP
plot_fire(pomdp::POMDP, s::WildfireState, a::WildfireAction; kwargs...) = plot_fire(pomdp.mdp, s, a; kwargs...)
function plot_fire(mdp::WildfireMDP, s::WildfireState, a::WildfireAction;
				   max_fuel=mdp.max_fuel, use_emojis=false, emoji_size=12, pop_color="#94442d")
	F = 𝟙.(s.burning) .* s.fuel
	xl = (0, size(F,1)) .+ 1/2
	yl = (0, size(F,2))	.+ 1/2
	heatmap(F, c=MCG, aspect_ratio=1, xlims=xl, ylims=yl, clims=(0, max_fuel))
	heatmap!(map(w->𝟙(w, eps(), NaN), mdp.walls), c=:black, clims=(0, max_fuel))
	heatmap!(map(b->𝟙(b, eps(), NaN), s.burnt), c=MCG, clims=(0, max_fuel))
    if use_emojis
        for pop in findall(mdp.population)
            annotate!([(pop.I[1], pop.I[2], text("🏘️", color=colorant"rgba(0,0,0,0.6)", halign=:center, pointsize=emoji_size, family="Times"))])
        end
    else
        heatmap!(map(p->𝟙(p, eps(), NaN), mdp.population), c=pop_color, alpha=0.7, clims=(0, max_fuel))
    end
	if a.action_type != NoAction
		A = fill(NaN, mdp.dims...)
		for aᵢ in a.locations
			# TODO: Observation...
			A[aᵢ...] = 1 # water placement
		end
		if a.action_type == ResourceAllocation
			action_color = :dodgerblue
			alpha = 1
		elseif a.action_type == AerialObservation
			action_color = :gray
			alpha = 0.5
		end
		heatmap!(A, c=action_color, alpha=alpha, clims=(0, max_fuel))
	end
    heatmap!(fill(NaN, size(s.burnt)), c=MCG, clims=(0, max_fuel)) # ensure last plot has the correct colorbar
	plot!(title="ignition",
		  grid=false,
		  ticks=false)
end

function plot_fuel(A; max_fuel=maximum(A))
	xl = (0, size(A,1)) .+ 1/2 # [9/24, 15/24]
	yl = (0, size(A,2))	.+ 1/2 # [9/24, 15/24]
	heatmap(A, c=:YlGn, aspect_ratio=1, xlims=xl, ylims=yl, clims=(0, max_fuel))
	plot!(title="fuel",
		  grid=false,
		  ticks=false)
end

plot_elevation(elevation) = plot_environment(elevation; c=CMAP_ELEVATION, title="elevation")
plot_terrain(terrain) = plot_environment(terrain; c=CMAP_TERRAIN, title="terrain")
function plot_environment(env; c=CMAP_TERRAIN, title="env")
    default(; PLOTTING_DEFAULTS...)
	dims = size(env)
	xl = (1, dims[1])
	yl = (1, dims[2])
	heatmap(env, xlims=xl, ylims=yl, c=c, aspect_ratio=1)
	title!(title)
end

function create_gif(mdp, h; filename="wildfire.gif", fps=4, kwargs...)
	frames = Frames(MIME("image/png"), fps=fps)
	for t in eachindex(h)
		frame = render(mdp, h[t].s, h[t].a; use_emojis=false, kwargs...)
		push!(frames, frame)
	end
	write(filename, frames)
    return frames
end
