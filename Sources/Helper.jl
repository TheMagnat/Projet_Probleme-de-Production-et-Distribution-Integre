
#=
Récupère le coût d'un circuit
=#
function getCircuitCost(circuit, costs)

	cost = 0
	for (from, to) in zip(circuit[1:end-1], circuit[2:end])
		cost += costs[(from, to)]
	end

	cost += costs[circuit[1], circuit[end]]

	return cost

end

#=
Récupère le coût d'une liste de circuits
=#
function getCircuitsCost(circuits, costs)

	cost = 0

	for circuit in circuits
		cost += getCircuitCost(circuit, costs)
	end

	return cost

end

#=
Convertie le résultat d'un VRP_MTZ en liste de circuits
=#
function vrpToCircuit(model, params)

	circuits = Vector{Int64}[]


	for i in 1:params["n"]
		#On cherche tout les chemin commençant en 0 (Début de circuit)
		if value(variable_by_name(model, "x[0,$i]")) > 0

			circuit = [0]
			#from deviant le premier noeud après 0 du circuit
			from = i

			#Puis tant qu'on a pas fais une boucle (Un circuit complet)...
			while from != 0

				#On ajout from ici pour ne pas avoir de 0 à la fin
				push!(circuit, from)

				for i in 0:params["n"]
					if i != from

						#...On cherche le noeud suivant from...
						if value(variable_by_name(model, "x[$from,$i]")) > 0
							#...Et ce noeud devient from
							from = i
							break
						end

					end
				end

			end

			push!(circuits, circuit)

		end
	end

	return circuits

end

#=
Retourne les VRP mais adapter a la vrai demande après un passage de LSP à chaque temps
=#
function getTrueVRP(params, nodes, demands, costs)


	model = createLSP(params, nodes, demands, costs)

	resolvePlne(model, 0)
	println()

	demandsAtT = Array{Int, 2}(undef, params["n"], params["l"]) #demandsAtT = qté à livrer u pas de temps t
	notEmptyIndexAtT = [[] for i in 1:params["l"]]

	for i in 1:params["n"]
		for t in 1:params["l"]
			demandsAtT[i, t] = value(variable_by_name(model, "q[$i,$t]"))

			if demandsAtT[i, t] != 0
				push!(notEmptyIndexAtT[t], i)
			end

		end
	end

	tToVrp = Any[]

	for t in 1:params["l"]

		#NOTE: CHOISIR LE t A TESTER ICI, PLUS TARD LE RETIRER ET METTRE LA BOUCLE
		#t=2


		#On copie les paramètres mais n prend la valeur du nombre de noeud avec une demande supérieur à 0
		copyParams = copy(params)
		copyParams["n"] = size(notEmptyIndexAtT[t], 1)


		#On copie les informations des noeuds mais dans sans les noeud avec une demande 0
		copyNodes = Array{Dict, 1}(undef, size(notEmptyIndexAtT[t], 1) + 1)

		#On copie les demande à chaque temps mais sans les noeud avec une demande à 0
		copyDemandsAtT = Array{Int64, 2}(undef, size(notEmptyIndexAtT[t], 1), params["l"])

		#Initialise le noeud 0 à part
		copyNodes[1] = nodes[0]
		
		for i in eachindex(notEmptyIndexAtT[t])
			copyNodes[i+1] = nodes[notEmptyIndexAtT[t][i]]
			copyDemandsAtT[i, :] = demandsAtT[notEmptyIndexAtT[t][i], :]
		end

		#On remet les index en commençant à 0
		copyNodes = OffsetVector(copyNodes, 0:(size(copyNodes, 1) - 1))

		#Un dictionnaire faisant le lien entre les anciens index et les nouveaux (Du au décalage d'index dans les array)
		isPresent = Dict{Int, Int}()

		for (index, elem) in enumerate(notEmptyIndexAtT[t])
			isPresent[elem] = index
		end

		isPresent[0] = 0

		#On copie les coûts de transports mais sans les arêtes passant par un noeud avec une demande à 0
		copyCost = Dict{Tuple{Int, Int}, Float64}()
		for (edge, edgeCost) in costs

			if in(edge[1], keys(isPresent)) && in(edge[2], keys(isPresent))
				copyCost[(isPresent[edge[1]], isPresent[edge[2]])] = edgeCost
			end

		end

		push!(tToVrp, (copyParams, copyNodes, copyDemandsAtT, copyCost))

	end

	return tToVrp

end

