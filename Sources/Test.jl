
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")

include("VRP_Heuristic.jl")


#Instances A
#INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
INSTANCE_PATH = "/Users/david_pinaud/Desktop/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS1_15_1.prp"

#Instances B
#INSTANCE_PATH = "../PRP_instances/B_200_instance20.prp"


function testGenerateGraph()

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	g = generateGraphComplet(nodes)

	generateGraphPDF(".", "graphe.pdf", g)

end


function testLSP(solve=false)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createLSP(params, nodes, demands, costs)

	if solve
		resolvePlne(model, 3)
	end

end


function testVRP_MTZ(solve=false, t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createVRP_MTZ(params, nodes, demands, costs, t)

	if solve
		resolvePlne(model, 1)
	end

end


function testLSP_Then_VRP_MTZ()

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createLSP(params, nodes, demands, costs)

	resolvePlne(model, 2)

	demandsAtT = Array{Int, 2}(undef, params["n"], params["l"])
	notEmptyIndexAtT = [[] for i in 1:params["l"]]

	for i in 1:params["n"]
		for t in 1:params["l"]
			demandsAtT[i, t] = value(variable_by_name(model, "q[$i,$t]"))

			if demandsAtT[i, t] != 0
				push!(notEmptyIndexAtT[t], i)
			end

		end
	end

	# for t in 1:params["l"]

		#NOTE: CHOISIR LE t A TESTER ICI, PLUS TARD LE RETIRER ET METTRE LA BOUCLE
		t=2


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

		modelVRP = createVRP_MTZ(copyParams, copyNodes, copyDemandsAtT, copyCost, t)
		resolvePlne(modelVRP, 1)

	# end



end


function testBinPacking(t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	createVRP_MTZ(params, nodes, demands, costs, t)

	binPacking(params, nodes, demands, costs, t)

end

function test_clark_wright(t=1)
	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	circuits=clark_wright(params,nodes,demands,costs,t)

	print(circuits)
end

#testGenerateGraph()
#testLSP(true)
#testVRP_MTZ(true)
#testLSP_Then_VRP_MTZ()

#testBinPacking()
test_clark_wright()


