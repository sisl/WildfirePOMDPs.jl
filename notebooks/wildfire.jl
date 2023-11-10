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

# ╔═╡ 14f47450-360d-4bc9-9105-a9366a0205a6
using MCTS

# ╔═╡ a2fa6419-1f6c-4fcc-9c99-8868165da54c
using Reel

# ╔═╡ 5500d8bf-44f8-4fce-aafb-f1783eaf1e44
using Logging

# ╔═╡ 3aef9abf-3575-4269-b42d-3c321359349c
mdp = WildfireMDP(
	dims=(50,50),
	num_water_drops=2,
	# p_ignite=0.25,
);

# ╔═╡ 77c7e608-dd85-483b-bd1d-ca7d4c849957
set_population!(mdp, collect(Iterators.product(2:2:10, 2:2:10)))

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
	policy = POMDPs.solve(DPWSolver(n_iterations=100), mdp)
end;

# ╔═╡ 1c03a0bc-eaa8-4f68-b000-e11965eccbc0
md"""
## Simulation
"""

# ╔═╡ 28641042-8c33-40c5-9086-20d075ca3f13
s0 = rand(initialstate(mdp));

# ╔═╡ 366f7e3a-d273-47e5-9d9f-3fc0c51b2c44
hr = HistoryRecorder(max_steps=100);

# ╔═╡ 3f97123e-3440-450c-bec1-64454e8bdaad
h = simulate(hr, mdp, policy, s0)

# ╔═╡ da514905-8c86-49ca-8950-9443e4c544be
@bind t Slider(eachindex(h))

# ╔═╡ b7008945-7e66-413b-a487-644a8549614b
render(mdp, h[t].s, h[t].a; use_emojis=false, emoji_size=6)

# ╔═╡ dd910b2f-9f8f-4257-a962-ca2f0ce06682
discounted_reward(h)

# ╔═╡ 66b62e38-d84c-4f87-adc4-3985a1def713
md"""
# GIF
"""

# ╔═╡ a91b21cb-d23d-4502-81c5-5cf5a7faedc4
create_gif(mdp, h; filename="../img/wildfire.gif", fps=10)

# ╔═╡ a4fb2a8f-a4de-4b2a-860b-c6e7744c1860
md"""
---
"""

# ╔═╡ 4be4d1d0-6916-48d1-8bba-9b02e85ce490
Logging.disable_logging(Logging.Warn) # NOTE: for colorbar warning in Plots

# ╔═╡ Cell order:
# ╟─5fad74f1-1824-4095-a6f5-536749b1ea42
# ╠═edef9782-3f87-4824-9fb3-513ab6f17b84
# ╠═3aef9abf-3575-4269-b42d-3c321359349c
# ╠═77c7e608-dd85-483b-bd1d-ca7d4c849957
# ╟─b212bcf6-8bc6-41e7-bcf7-c3e060ed3f95
# ╠═b308e928-f284-4c08-8fba-fc6b5d0dd6ae
# ╠═14f47450-360d-4bc9-9105-a9366a0205a6
# ╠═6a49bd7b-95b7-4223-8e46-030cb9b86ef0
# ╟─1c03a0bc-eaa8-4f68-b000-e11965eccbc0
# ╠═28641042-8c33-40c5-9086-20d075ca3f13
# ╠═366f7e3a-d273-47e5-9d9f-3fc0c51b2c44
# ╠═3f97123e-3440-450c-bec1-64454e8bdaad
# ╠═da514905-8c86-49ca-8950-9443e4c544be
# ╠═b7008945-7e66-413b-a487-644a8549614b
# ╠═dd910b2f-9f8f-4257-a962-ca2f0ce06682
# ╟─66b62e38-d84c-4f87-adc4-3985a1def713
# ╠═a2fa6419-1f6c-4fcc-9c99-8868165da54c
# ╠═a91b21cb-d23d-4502-81c5-5cf5a7faedc4
# ╟─a4fb2a8f-a4de-4b2a-860b-c6e7744c1860
# ╠═5500d8bf-44f8-4fce-aafb-f1783eaf1e44
# ╠═4be4d1d0-6916-48d1-8bba-9b02e85ce490
