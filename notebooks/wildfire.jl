### A Pluto.jl notebook ###
# v0.19.32

using Markdown
using InteractiveUtils

# This Pluto notebook uses @bind for interactivity. When running this notebook outside of Pluto, the following 'mock version' of @bind gives bound variables a default value (instead of an error).
macro bind(def, element)
    quote
        local iv = try Base.loaded_modules[Base.PkgId(Base.UUID("6e696c72-6542-2067-7265-42206c756150"), "AbstractPlutoDingetjes")].Bonds.initial_value catch; b -> missing; end
        local el = $(esc(element))
        global $(esc(def)) = Core.applicable(Base.get, el) ? Base.get(el) : iv(el)
        el
    end
end

# ╔═╡ 5fad74f1-1824-4095-a6f5-536749b1ea42
begin
	# Front matter
	using PlutoUI; TableOfContents()
	using Revise

	using Pkg
	Pkg.develop(path="..")

	md"""
	# Wildfire MDP
	"""
end

# ╔═╡ edef9782-3f87-4824-9fb3-513ab6f17b84
using WildfirePOMDPs

# ╔═╡ a68b3eaa-f7a8-4c66-a66c-116f899f84a2
using Parameters

# ╔═╡ ac1f57b7-465d-4f4d-9b3d-a183ae128372
using LinearAlgebra

# ╔═╡ 14f47450-360d-4bc9-9105-a9366a0205a6
using MCTS

# ╔═╡ 5500d8bf-44f8-4fce-aafb-f1783eaf1e44
using Logging

# ╔═╡ 3aef9abf-3575-4269-b42d-3c321359349c
mdp = WildfireMDP(
	# dims=(32,32),
	# dims=(50,50),
	# dims=(100,100),
	# num_water_drops=2,
	# p_ignite=0.25,
	# action_size=(2,20),
	# p_ignite=0.25,
	# allow_non_burning_actions=true,
);

# ╔═╡ 77c7e608-dd85-483b-bd1d-ca7d4c849957
if mdp.dims == (10,10)
	set_population!(mdp, collect(Iterators.product(1:3, 1:3)))
else
	set_population!(mdp, collect(Iterators.product(2:10, 2:10)))
end

# ╔═╡ c36f6db8-8312-49cb-8961-09b2c8d4b673
args = (ratio=1, size=(300,300), colorbar=false, ticks=false);

# ╔═╡ 86010b8b-3125-401a-83b6-090f05c0fb3e
md"""
## POMDPS
"""

# ╔═╡ 5fe68c84-bd12-4f0f-a7bd-e2c63518f556
pomdp = WildfirePOMDP(mdp=mdp, σ_abc=0.1)

# ╔═╡ b85e187d-e47f-4675-8920-b220403c5634
up = BootstrapFilter(pomdp, 20)
# up = wfup

# ╔═╡ 2646d439-f41f-44d8-a107-efa995c76105
ds0 = initialstate(mdp)

# ╔═╡ c40fb6f7-dea2-44d2-a2ed-b3f71d0eeafd
# a = rand(actions(pomdp.mdp)) # TODO

# ╔═╡ 916c84b2-e78f-4f9b-9d32-bc7530233840
a = WildfireAction() # rand(actions(pomdp.mdp, s0))

# ╔═╡ 0b4a4f5d-1a05-4357-a206-d043c62f3dee
cmap = cgrad(WildfirePOMDPs.CMAP_FIRE.colors)

# ╔═╡ 63343cd9-6bd4-4ad6-a604-3f7f3328faa0
[[1,2,3] [4,5,6]]

# ╔═╡ 253648f7-bba2-4447-a083-807730e47241
md"""
## Intented belief
"""

# ╔═╡ 98ccb13f-7a87-4204-a374-8a057d093a5b
md"""
## Wildfire belief
"""

# ╔═╡ 2ec71f44-d2cd-4f48-bc02-bb53daa360ac
# @with_kw struct WildfireBelief
# 	dims
# 	max_fuel::Real = WildfirePOMDPs.DEFAULT_MAX_FUEL
# 	burning::Matrix = falses(dims...)
# 	fuel::Matrix = falses(dims...)
# 	p_burning::Matrix = fill(0.5, dims...)
# 	σ_fuel::Matrix = fill(max_fuel, dims...)
# end

# ╔═╡ c820ee2f-a29b-4cf5-be3b-99ee99dbecae
begin
	@with_kw mutable struct WildfireBelief
		dims
		B = [Bernoulli(0) for _ in 1:dims[1], _ in 1:dims[2]]
		max_fuel = WildfirePOMDPs.DEFAULT_MAX_FUEL
		fuel::Matrix{Real} = max_fuel*ones(dims...)
	    burnt::Matrix{Union{<:Bool,<:Real}} = falses(dims...)
		terrain = WildfirePOMDPs.generate_terrain(dims; max_fuel)
	end

	function WildfireBelief(P)
		dims = size(P)
		B = [Bernoulli(P[i,j]) for i in 1:dims[1], j in 1:dims[2]]
		return WildfireBelief(; dims, B)
	end
end

# ╔═╡ 232433ae-9515-4086-ba3e-c470f96499a0
@with_kw struct WildfireBeliefUpdater <: Updater
	pomdp::WildfirePOMDP
	n_samples
end

# ╔═╡ c6101f64-2f13-491b-870b-c300c20bc01c
wfup = WildfireBeliefUpdater(pomdp, 20);

# ╔═╡ 82be8fba-67ba-4143-bdbb-dab8c6ca430a
b = WildfireBelief(dims=mdp.dims)

# ╔═╡ a179d9dd-5059-47f4-8b7c-41c945661dd3
function Base.rand(rng::AbstractRNG, b::WildfireBelief)
	dims = b.dims
	burning = rand.(rng, b.B)
	max_fuel = b.max_fuel
	fuel = b.fuel # TODO
	burnt = b.burnt # TODO
	terrain = b.terrain # TODO
	return WildfireState(; dims, burning, max_fuel, fuel, burnt, terrain)
end

# ╔═╡ 94f2c1ef-68e6-4f42-902c-b6daf4c96860
rand(ds0)

# ╔═╡ 8b7488a2-bf6f-4b36-97e0-a65c92b000cd
function POMDPs.update(up::WildfireBeliefUpdater, b::WildfireBelief,
	                   a::WildfireAction, o::WildfireObservation)
	bp = deepcopy(b)
	if a.action_type != NoAction
		for (ai,loc) in enumerate(a.locations)
			bp.B[loc...] = Bernoulli(o[ai,1])
		end
	end
	# progress fire dynamics model
	s = rand(bp)
	SP = [rand(transition(pomdp, s, a)) for _ in 1:up.n_samples]
	SP_bar = mean(SP)
	bp = WildfireBelief(SP_bar.burning)
	bp.fuel = SP_bar.fuel # TODO
	bp.burnt = SP_bar.burnt # TODO
	bp.terrain = SP_bar.terrain # TODO
	return bp
end

# ╔═╡ 67da5553-db38-4671-9b16-330a2b03f48d
function POMDPs.initialize_belief(up::WildfireBeliefUpdater, ds0)
	S = [rand(ds0) for _ in 1:up.n_samples]
	S̄ = mean(S)
	return WildfireBelief(S̄.burning)
end

# ╔═╡ 7961f296-3771-4972-832a-563dd7c3d4f4
b0 = initialize_belief(up, ds0)

# ╔═╡ 655c286f-ec20-4f9f-a8a6-c07e6f9c4543
s0 = rand(b0)

# ╔═╡ e7656624-79b7-4a1d-bbf6-e8ad63f141d8
heatmap(𝟙.(s0.burning) .* s0.fuel; args...)

# ╔═╡ 4cbf42cc-0e23-4681-b61a-e3ba4790a2f6
heatmap(𝟙.(s0.burning) .* s0.fuel; args...)

# ╔═╡ 3d789ac7-6544-4221-bc0b-09e84c2fd17e
begin
	𝐬 = [s0 for _ in 1:up.n_init]
	for t in 1:30
		global 𝐬
		𝐬 = [@gen(:sp)(pomdp, s, WildfireAction()) for s in 𝐬]
	end
end

# ╔═╡ f71c9cdf-ad50-426c-b840-1e4fea02cda0
begin
	plt_b = heatmap(mean(𝐬).burning, c=:jet, ratio=1, size=(300,300), colorbar=false, ticks=false)
	plt_bpred = heatmap(mean(𝐬).burning .> 0.5, ratio=1, size=(300,300), colorbar=false, ticks=false, c=cgrad([:white, "#373737"]))
	plot(plt_b, plt_bpred, size=(600,300))
end

# ╔═╡ 864a01f8-7bd7-46a5-b3ec-18444f55d757
μb̃ = mean(b0)

# ╔═╡ ab668155-46a6-4018-b712-61f918e9ed38
plot_fire(pomdp, μb̃, a)

# ╔═╡ b1093c97-23d0-4d80-82cb-f4e0eef65c61
σb̃ = std(b0)

# ╔═╡ b2fb3d49-99b0-429b-95b0-6149f585c2be
heatmap(σb̃.fuel; args...)

# ╔═╡ 76165d6c-c9d3-4af2-945c-1a736d6822b5
σ²b̃ = var(b0)

# ╔═╡ 988cf0ad-5e5f-44e3-ab52-50f2bb02d29a
plot(heatmap(μb̃.burning, ; c=cmap, args...), heatmap(σ²b̃.burning; c=:viridis, args...), size=(600,300))

# ╔═╡ 0ab988cf-8085-4776-8208-cd3f00fef624
S = [rand(ds0) for _ in 1:up.n_samples]

# ╔═╡ cb1aebf5-2814-49f5-ba99-07cabf8515f7
S̄ = mean(S)

# ╔═╡ 5088b7f7-c40e-41a6-9bd9-f2edc2c309d5
mean(S)

# ╔═╡ 86e597d3-7532-4158-b5b4-5958f6bc52b4
heatmap(s0.burning; args...)

# ╔═╡ 134a8021-d2b3-4744-b0c7-55d899712bb4
mean.(b.B)

# ╔═╡ 1a586749-a893-4f05-952f-9a59afdb7044
std.(b.B)

# ╔═╡ 98c18240-8f3c-4b94-b6ff-33f40af23d65
md"""
# Particle filter
"""

# ╔═╡ 83d19acc-3804-49b7-ae63-22fb07b1b006
@gen(:sp)(pomdp, s0, a)

# ╔═╡ 4f95d106-1fd8-4361-96da-1293f59502d8
function particle_filter(pomdp::POMDP, b::Vector, a, o)
	𝐬′ = map(s->rand(transition(pomdp, s, a)), b) # next states
	𝐰 = map(s′->obs_weight(pomdp, s′, a, s′, o), 𝐬′) # weights
	if sum(𝐰) ≈ 0
		𝐰 = ones(length(𝐰))
	end
	𝒞 = Categorical(normalize(𝐰, 1))
	return 𝐬′[rand(𝒞, length(𝐬′))] # sample with normalized weights
end

# ╔═╡ 677fc974-993e-48f7-b904-42ab97f8fd77
# b′ = particle_filter(pomdp, particles(step_pomdp.b), step_pomdp.a, step_pomdp.o)

# ╔═╡ 5b75dced-7047-4a1a-b9ee-38d175505ff3
# heatmap(mean(particles(step_pomdp.b)).burning, ratio=1)

# ╔═╡ 86d7ebf3-189d-4bf6-bf26-a040aa6c6905
# heatmap(mean(b′).burning, ratio=1)

# ╔═╡ 515e2f9b-9d0c-478c-ab3c-7b3542aaad48
# particles(b0)

# ╔═╡ fe50fcb9-414f-40bf-8528-bf040f06a530
md"""
## POMDP step through
"""

# ╔═╡ ff029dac-ecd9-4c02-b63d-b858967c65ea
sp, r = gen(mdp, s0, a, Random.default_rng())

# ╔═╡ 58282cef-e9b3-4afc-afe1-e4494036755e
# for s in particles(step_pomdp.b)
# 	@info obs_weight(pomdp, s, step_pomdp.a, step_pomdp.sp, step_pomdp.o)
# end

# ╔═╡ 1bd530b4-9b6c-4751-9042-eb82faaf1b88
function plot_belief(b::ParticleCollection)
	μb = mean(b)
	σb = std(b)
	plt_fire = heatmap(μb.burning; c=cmap, args...)
	plt_fuel = heatmap(σb.burning; c=:viridis, args...)
	plot(plt_fire, plt_fuel, size=(600,300))
end

# ╔═╡ 24c4933a-e8bf-442e-92c5-4f51ca3b76e8
function plot_belief(b::WildfireBelief)
	μb = mean.(b.B)
	σb = std.(b.B)
	plt_fire = heatmap(μb; c=cmap, args...)
	plt_fuel = heatmap(σb; c=:viridis, args...)
	plot(plt_fire, plt_fuel, size=(600,300))
end

# ╔═╡ b212bcf6-8bc6-41e7-bcf7-c3e060ed3f95
md"""
## Policy
"""

# ╔═╡ b308e928-f284-4c08-8fba-fc6b5d0dd6ae
md"Use the random policy? $(@bind use_random CheckBox(true))"

# ╔═╡ 6a49bd7b-95b7-4223-8e46-030cb9b86ef0
if use_random
	policy = RandomPolicy(mdp)
else
	policy = POMDPs.solve(DPWSolver(n_iterations=1), mdp)
end;

# ╔═╡ 1c03a0bc-eaa8-4f68-b000-e11965eccbc0
md"""
## Simulation
"""

# ╔═╡ 366f7e3a-d273-47e5-9d9f-3fc0c51b2c44
hr = HistoryRecorder(max_steps=100);

# ╔═╡ 3f97123e-3440-450c-bec1-64454e8bdaad
# h = simulate(hr, mdp, policy, s0)

# ╔═╡ c42e08a4-9727-45f9-ab6e-8a2a16e7cc80
h = simulate(hr, mdp, FunctionPolicy(x->WildfireAction()), s0)

# ╔═╡ da514905-8c86-49ca-8950-9443e4c544be
@bind t Slider(eachindex(h), show_value=true)

# ╔═╡ b7008945-7e66-413b-a487-644a8549614b
render(mdp, h[t].s, h[t].a)

# ╔═╡ 5fb7706f-c685-42f1-8429-ff9461421dbc
A = actions(pomdp)

# ╔═╡ df24327b-9d00-4eae-8ec8-fd2988cb2dfc
o = observation(pomdp, A[end], s0)

# ╔═╡ 399fb10e-7d99-4836-b51f-c610b0f1b392
o

# ╔═╡ 5399a6e2-b70e-497e-9efc-661d988c1c44
burning = map(location->𝟙(s0.burning[location...]), A[end].locations)

# ╔═╡ 6bcb3010-d1ee-496a-b402-60bac5405b7e
fuel = map(location->s0.fuel[location...], A[end].locations)

# ╔═╡ fe8d9c6d-e78a-4668-a8f3-34cf4c9a1f3d
A[end].locations

# ╔═╡ d0f4570c-24ae-4988-a8a8-720cd2ba6c69
hcat(
	map(location->s0.burning[location...], A[end].locations),
	map(location->s0.fuel[location...], A[end].locations)
)

# ╔═╡ 30e90504-4a9e-4925-8e36-bbe5f5ac9bd5
begin
	pomdp_policy = FunctionPolicy(x->rand(A[514:518]))
	# pomdp_policy = RandomPolicy(pomdp)
	# pomdp_policy = FunctionPolicy(x->rand(A[501:end]))
	h_pomdp = simulate(HistoryRecorder(max_steps=3), pomdp, pomdp_policy, up)
end

# ╔═╡ 99d551c9-4978-4e44-8077-46c89d0a6448
h_pomdp[end].b

# ╔═╡ a6c1d6a1-b952-472c-92cf-651453d657c1
h_pomdp[1].o[:,1]

# ╔═╡ 84645037-20e6-4875-8bf5-07d2567ea046
@bind tp Slider(eachindex(h_pomdp), show_value=true)

# ╔═╡ 2fa78a76-503f-4017-bb5b-bd480513c032
step_pomdp = h_pomdp[tp];

# ╔═╡ d0f79f4d-b299-45eb-a035-e994f6ef76a1
bp = update(wfup, b, step_pomdp.a, step_pomdp.o)

# ╔═╡ d62130af-4a09-4646-b17c-c0e09c1fc167
heatmap(rand.(bp.B); args...)

# ╔═╡ 5cf5d576-9396-4e74-b1ce-cbdd7f8f8132
render(mdp, h_pomdp[tp].s, h_pomdp[tp].a)

# ╔═╡ b9368670-e3c3-44fc-a4bc-dbf559959ab8
plot_belief(h_pomdp[tp].b)

# ╔═╡ 8058aab4-7d0d-4596-bf74-3f173859321f
@bind ai Slider(eachindex(A), show_value=true, default=length(A))

# ╔═╡ a5dde8bd-50d8-4409-850f-d8aa4e5be95f
a0 = A[ai]

# ╔═╡ 7458aeb5-06ba-4fda-8765-88687be6d741
render(mdp, s0, a0)

# ╔═╡ dd910b2f-9f8f-4257-a962-ca2f0ce06682
discounted_reward(h)

# ╔═╡ f434a575-d1ab-485f-b316-a6924c068af0
isfailure(mdp, h[t].s)

# ╔═╡ 56972758-6de1-416b-8861-b57c83c5ddd0
isfailure(mdp, h)

# ╔═╡ 13d5e24c-b861-45c1-b232-a5c79b735909
md"""
## Terrain (MvNormal)
"""

# ╔═╡ 471bff96-6a9f-484d-a648-e07b755c0e80
terrain = s0.terrain;

# ╔═╡ 0cb2f7bf-fb16-4e2b-8b49-03db17474698
heatmap(1:mdp.dims[1], 1:mdp.dims[2], terrain; clims=(0, mdp.max_fuel), args...)

# ╔═╡ f1385a23-5943-4d5d-b004-ac7cde39483f
md"""
# Wildfire POMDP
"""

# ╔═╡ 7f92cb3e-8d09-47b7-b08b-1b2642b7a781
md"""
- State uncertainty:
  - location of fire...
  - terrain
- Actions:
  - Observe box/region
  - 
"""

# ╔═╡ a0e0b0f4-51f2-4a10-8d7b-a33b72b8644d
md"""
# Extended Kalman filter (EKF)
"""

# ╔═╡ d94e80c3-c96d-4810-8fcf-b5f4740169cc
# import ForwardDiff: jacobian

# ╔═╡ fdae8c52-9567-403b-af23-158680001ea1
# struct ExtendedKalmanFilter
# 	μ # mean vector
# 	Σ # covariance matrix
# end

# ╔═╡ bed93d91-b3aa-45fb-bd4b-0da9595f9012
# function POMDPs.update(b::ExtendedKalmanFilter, 𝒫, a, o)
# 	μ, Σ = b.μ, b.Σ
# 	fT, fO = 𝒫.fT, 𝒫.fO
# 	Σs, Σo = 𝒫.Σs, 𝒫.Σo
# 	# predict
# 	μp = fT(μ, a)
# 	Ts = jacobian(s->fT(s, a), μ)
# 	Os = jacobian(fO, μp)
# 	Σp = Ts*Σ*Ts' + Σs
# 	# update
# 	Σpo = Σp*Os'
# 	K = Σpo/(Os*Σp*Os' + Σo) # Kalman gain
# 	μ′ = μp + K*(o - fO(μp))
# 	Σ′ = (I - K*Os)*Σp
# 	return ExtendedKalmanFilter(μ′, Σ′)
# end

# ╔═╡ 66b62e38-d84c-4f87-adc4-3985a1def713
md"""
# GIF
"""

# ╔═╡ a2fa6419-1f6c-4fcc-9c99-8868165da54c
# ╠═╡ disabled = true
#=╠═╡
using Reel
  ╠═╡ =#

# ╔═╡ a91b21cb-d23d-4502-81c5-5cf5a7faedc4
# ╠═╡ disabled = true
#=╠═╡
create_gif(mdp, h; filename="../img/wildfire.gif", fps=10)
  ╠═╡ =#

# ╔═╡ a4fb2a8f-a4de-4b2a-860b-c6e7744c1860
md"""
---
"""

# ╔═╡ ebc434b7-b3d9-4449-963e-7fa112625ca3
TableOfContents()

# ╔═╡ 4be4d1d0-6916-48d1-8bba-9b02e85ce490
Logging.disable_logging(Logging.Warn) # NOTE: for colorbar warning in Plots

# ╔═╡ Cell order:
# ╟─5fad74f1-1824-4095-a6f5-536749b1ea42
# ╠═edef9782-3f87-4824-9fb3-513ab6f17b84
# ╠═3aef9abf-3575-4269-b42d-3c321359349c
# ╠═77c7e608-dd85-483b-bd1d-ca7d4c849957
# ╠═c36f6db8-8312-49cb-8961-09b2c8d4b673
# ╠═e7656624-79b7-4a1d-bbf6-e8ad63f141d8
# ╟─86010b8b-3125-401a-83b6-090f05c0fb3e
# ╠═5fe68c84-bd12-4f0f-a7bd-e2c63518f556
# ╠═b85e187d-e47f-4675-8920-b220403c5634
# ╠═2646d439-f41f-44d8-a107-efa995c76105
# ╠═7961f296-3771-4972-832a-563dd7c3d4f4
# ╠═655c286f-ec20-4f9f-a8a6-c07e6f9c4543
# ╠═4cbf42cc-0e23-4681-b61a-e3ba4790a2f6
# ╠═864a01f8-7bd7-46a5-b3ec-18444f55d757
# ╠═b1093c97-23d0-4d80-82cb-f4e0eef65c61
# ╠═76165d6c-c9d3-4af2-945c-1a736d6822b5
# ╠═c40fb6f7-dea2-44d2-a2ed-b3f71d0eeafd
# ╠═94f2c1ef-68e6-4f42-902c-b6daf4c96860
# ╠═916c84b2-e78f-4f9b-9d32-bc7530233840
# ╠═ab668155-46a6-4018-b712-61f918e9ed38
# ╠═0b4a4f5d-1a05-4357-a206-d043c62f3dee
# ╠═988cf0ad-5e5f-44e3-ab52-50f2bb02d29a
# ╠═b2fb3d49-99b0-429b-95b0-6149f585c2be
# ╠═df24327b-9d00-4eae-8ec8-fd2988cb2dfc
# ╠═5399a6e2-b70e-497e-9efc-661d988c1c44
# ╠═6bcb3010-d1ee-496a-b402-60bac5405b7e
# ╠═fe8d9c6d-e78a-4668-a8f3-34cf4c9a1f3d
# ╠═d0f4570c-24ae-4988-a8a8-720cd2ba6c69
# ╠═63343cd9-6bd4-4ad6-a604-3f7f3328faa0
# ╟─253648f7-bba2-4447-a083-807730e47241
# ╠═3d789ac7-6544-4221-bc0b-09e84c2fd17e
# ╠═f71c9cdf-ad50-426c-b840-1e4fea02cda0
# ╟─98ccb13f-7a87-4204-a374-8a057d093a5b
# ╠═a68b3eaa-f7a8-4c66-a66c-116f899f84a2
# ╠═2ec71f44-d2cd-4f48-bc02-bb53daa360ac
# ╠═c820ee2f-a29b-4cf5-be3b-99ee99dbecae
# ╠═232433ae-9515-4086-ba3e-c470f96499a0
# ╠═c6101f64-2f13-491b-870b-c300c20bc01c
# ╠═82be8fba-67ba-4143-bdbb-dab8c6ca430a
# ╠═8b7488a2-bf6f-4b36-97e0-a65c92b000cd
# ╠═a179d9dd-5059-47f4-8b7c-41c945661dd3
# ╠═67da5553-db38-4671-9b16-330a2b03f48d
# ╠═0ab988cf-8085-4776-8208-cd3f00fef624
# ╠═cb1aebf5-2814-49f5-ba99-07cabf8515f7
# ╠═5088b7f7-c40e-41a6-9bd9-f2edc2c309d5
# ╠═d0f79f4d-b299-45eb-a035-e994f6ef76a1
# ╠═d62130af-4a09-4646-b17c-c0e09c1fc167
# ╠═86e597d3-7532-4158-b5b4-5958f6bc52b4
# ╠═134a8021-d2b3-4744-b0c7-55d899712bb4
# ╠═1a586749-a893-4f05-952f-9a59afdb7044
# ╟─98c18240-8f3c-4b94-b6ff-33f40af23d65
# ╠═ac1f57b7-465d-4f4d-9b3d-a183ae128372
# ╠═83d19acc-3804-49b7-ae63-22fb07b1b006
# ╠═4f95d106-1fd8-4361-96da-1293f59502d8
# ╠═399fb10e-7d99-4836-b51f-c610b0f1b392
# ╠═677fc974-993e-48f7-b904-42ab97f8fd77
# ╠═5b75dced-7047-4a1a-b9ee-38d175505ff3
# ╠═86d7ebf3-189d-4bf6-bf26-a040aa6c6905
# ╠═515e2f9b-9d0c-478c-ab3c-7b3542aaad48
# ╟─fe50fcb9-414f-40bf-8528-bf040f06a530
# ╠═30e90504-4a9e-4925-8e36-bbe5f5ac9bd5
# ╠═ff029dac-ecd9-4c02-b63d-b858967c65ea
# ╠═99d551c9-4978-4e44-8077-46c89d0a6448
# ╠═a6c1d6a1-b952-472c-92cf-651453d657c1
# ╠═2fa78a76-503f-4017-bb5b-bd480513c032
# ╠═58282cef-e9b3-4afc-afe1-e4494036755e
# ╠═84645037-20e6-4875-8bf5-07d2567ea046
# ╠═5cf5d576-9396-4e74-b1ce-cbdd7f8f8132
# ╠═b9368670-e3c3-44fc-a4bc-dbf559959ab8
# ╠═1bd530b4-9b6c-4751-9042-eb82faaf1b88
# ╠═24c4933a-e8bf-442e-92c5-4f51ca3b76e8
# ╟─b212bcf6-8bc6-41e7-bcf7-c3e060ed3f95
# ╟─b308e928-f284-4c08-8fba-fc6b5d0dd6ae
# ╠═14f47450-360d-4bc9-9105-a9366a0205a6
# ╠═6a49bd7b-95b7-4223-8e46-030cb9b86ef0
# ╟─1c03a0bc-eaa8-4f68-b000-e11965eccbc0
# ╠═366f7e3a-d273-47e5-9d9f-3fc0c51b2c44
# ╠═3f97123e-3440-450c-bec1-64454e8bdaad
# ╠═c42e08a4-9727-45f9-ab6e-8a2a16e7cc80
# ╠═da514905-8c86-49ca-8950-9443e4c544be
# ╠═b7008945-7e66-413b-a487-644a8549614b
# ╠═5fb7706f-c685-42f1-8429-ff9461421dbc
# ╠═8058aab4-7d0d-4596-bf74-3f173859321f
# ╠═a5dde8bd-50d8-4409-850f-d8aa4e5be95f
# ╠═7458aeb5-06ba-4fda-8765-88687be6d741
# ╠═dd910b2f-9f8f-4257-a962-ca2f0ce06682
# ╠═f434a575-d1ab-485f-b316-a6924c068af0
# ╠═56972758-6de1-416b-8861-b57c83c5ddd0
# ╟─13d5e24c-b861-45c1-b232-a5c79b735909
# ╠═471bff96-6a9f-484d-a648-e07b755c0e80
# ╠═0cb2f7bf-fb16-4e2b-8b49-03db17474698
# ╟─f1385a23-5943-4d5d-b004-ac7cde39483f
# ╟─7f92cb3e-8d09-47b7-b08b-1b2642b7a781
# ╟─a0e0b0f4-51f2-4a10-8d7b-a33b72b8644d
# ╠═d94e80c3-c96d-4810-8fcf-b5f4740169cc
# ╠═fdae8c52-9567-403b-af23-158680001ea1
# ╠═bed93d91-b3aa-45fb-bd4b-0da9595f9012
# ╟─66b62e38-d84c-4f87-adc4-3985a1def713
# ╠═a2fa6419-1f6c-4fcc-9c99-8868165da54c
# ╠═a91b21cb-d23d-4502-81c5-5cf5a7faedc4
# ╟─a4fb2a8f-a4de-4b2a-860b-c6e7744c1860
# ╠═ebc434b7-b3d9-4449-963e-7fa112625ca3
# ╠═5500d8bf-44f8-4fce-aafb-f1783eaf1e44
# ╠═4be4d1d0-6916-48d1-8bba-9b02e85ce490
