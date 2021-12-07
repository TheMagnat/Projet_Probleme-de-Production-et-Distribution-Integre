
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")
include("PDI_exact_resolution.jl")
include("VRP_Heuristic.jl")
include("Helper.jl")
include("PDI_heuristic_resolution.jl")

include("GraphHelper.jl")

#Instances A
#INSTANCE_PATH = "./PRP_instances/A_014_#ABS1_15_1.prp"
#INSTANCE_PATH = "./PRP_instances/A_050_ABS14_50_1.prp"
#INSTANCE_PATH = "./PRP_instances/A_100_ABS5_100_4.prp"
INSTANCE_PATH = "/Users/davidpinaud/Desktop/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS1_15_1.prp"
#INSTANCE_PATH="/Users/davidpinaud/GitHub/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_050_ABS14_50_1.prp"

#Instances B
#INSTANCE_PATH = "../PRP_instances/B_200_instance20.prp"


function testGenerateGraph()

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	g = generateGraphComplet(nodes)

	generateGraphPDF(".", "graphe.pdf", g)

end


function testLSP(solve=false, verbose=3)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createLSP(params, nodes, demands, costs)

	if solve
		resolvePlne(model, verbose)
	end

end


function testVRP_MTZ(solve=false, t=1, verbose=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createVRP_MTZ(params, nodes, demands, costs, t)

	if solve
		resolvePlne(model, verbose)
	end

end

function testPDI_Bard_Nananukul(solve=false, verbose=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)
	if solve
		resolvePlne(model, verbose)
	end
	return model

end

function testPDI_heuristique(resoudreVRPwithHeuristic=true,nbMaxIte=10)

	lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial=initialisation_PDI_heuristique(INSTANCE_PATH)
	lsp_model=PDI_heuristique(lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial, nbMaxIte, resoudreVRPwithHeuristic)

end




#=
t: choisir le temps sur lequel tester
choice: Choisir l'heuristique à utiliser
metaChoice: Choisir la métaheuristique à utiliser (0 si aucune)

showCircuits: Montrer ou non les circuits des heuristiques/métaheuristiques

useLSP: Si vrai, appliquer d'abord le LSP pour obtenir les vrai valeur de VRP

showMTZ:
	0: Ne pas montrer le résultat de MTZ
	1: Montrer le résultat de MTZ
	2: Montrer le circuit de MTZ
	3: Ne montrer que MTZ et pas l'heuristique

	ATTENTION: MTZ sur des instances de plus de 14 risque de prendre très longtemps

heuristicExtraParam:
	Paramètre en plus de ceux de base pour l'heuristique (Exemple l'angle pour sectorielle)

=#
function testHeuristicVRP(;t=1, choice=1, metaChoice=0, showCircuits=false, useLSP=false, showMTZ=0, heuristicExtraParam=[], savePath="")
	allHeuristic = [[binPacking, "Bin packing"], [clark_wright, "Clark-Wright"], [sectorielle, "Sectorielle"]]
	allMetaheuristic = [[TSPBoost, "TSP Local search"], [mixMetaheuristic, "Mix Metaheuristic"]]

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	if useLSP

		tToVRP = getTrueVRP(params, nodes, demands, costs)
		params, nodes, demands, costs = tToVRP[t]

	end

	if showMTZ > 0

		modelVRP = createVRP_MTZ(params, nodes, demands, costs, t)
		resolvePlne(modelVRP, 0)

		println("\nMTZ objective value: ", objective_value(modelVRP))
		

		if showMTZ > 1
			circuits = vrpToCircuit(modelVRP, params)
			totalCost = getCircuitsCost(circuits, costs)

			println("MTZ circuits: ", circuits)
			println("MTZ circuits cost: ", totalCost)

			if showMTZ > 2
				return
			end

		end

		println()

	end

	heuristic = allHeuristic[choice]

	if choice < 3
		heuristicExtraParam = []
	end
	circuits = heuristic[1](params, nodes, demands, costs, t, heuristicExtraParam...)
	totalCost = getCircuitsCost(circuits, costs)


	if showCircuits
		println("$(heuristic[2]) circuits: ", circuits)
	end
	
	println("$(heuristic[2]) circuits cost: ", totalCost)


	if metaChoice > 0
		println()

		metaheuristic = allMetaheuristic[metaChoice]

		circuits = metaheuristic[1](circuits, params, costs)
		totalCost = getCircuitsCost(circuits, costs)

		if showCircuits
			println("$(metaheuristic[2]) circuits: ", circuits)
		end

		println("$(metaheuristic[2]) circuits cost: ", totalCost)

	end

	if length(savePath) > 0
		saveCircuits(params, circuits, savePath)
	end

end
function testPDI_Boudia(solve=false, verbose=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createPDI_Boudia(params, nodes, demands, costs)
	if solve
		resolvePlne(model, verbose)
	end

end
#testGenerateGraph()
#testLSP(true)
#testVRP_MTZ(true)

#Nouvelle fonction qui réunis toutes les heuristique, le MTZ et le LSP

#testHeuristicVRP(t=2, choice=3, metaChoice=2, showCircuits=false, useLSP=false, heuristicExtraParam=[30], showMTZ=0, savePath="../Save/test.png")

#testHeuristicVRP(t=4, choice=3, metaChoice=2, showCircuits=false, useLSP=true, heuristicExtraParam=[30], showMTZ=0)
#testPDI_heuristique()

#testPDI_Boudia(true)
testPDI_Bard_Nananukul(true,2)
