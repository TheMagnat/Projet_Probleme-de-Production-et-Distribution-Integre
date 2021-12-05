
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")

include("VRP_Heuristic.jl")
include("Helper.jl")


#Instances A
#INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
#INSTANCE_PATH = "../PRP_instances/A_050_ABS14_50_1.prp"
INSTANCE_PATH = "../PRP_instances/A_100_ABS5_100_4.prp"
#INSTANCE_PATH = "/Users/davidpinaud/Desktop/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS1_15_1.prp"
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



#=
t: choisir le temps sur lequel tester
choice: Choisir l'heuristique à utiliser
useLSP: Si vrai, appliquer d'abord le LSP pour obtenir les vrai valeur de VRP

showMTZ:
	0: Ne pas montrer le résultat de MTZ
	1: Montrer le résultat de MTZ
	2: Montrer le circuit de MTZ
	3: Ne montrer que MTZ et pas l'heuristique

heuristicExtraParam:
	Paramètre en plus de ceux de base pour l'heuristique (Exemple l'angle pour sectorielle)

=#
function testHeuristicVRP(;t=1, choice=1, useLSP=false, showMTZ=0, heuristicExtraParam=[])
	allHeuristic = [binPacking, clark_wright, sectorielle]

	heuristic = allHeuristic[choice]

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

	circuits = heuristic(params, nodes, demands, costs, t, heuristicExtraParam...)
	totalCost = getCircuitsCost(circuits, costs)

	#println("Heuristic circuits: ", circuits)
	println("Circuits cost: ", totalCost)

end

#testGenerateGraph()
#testLSP(true)
#testVRP_MTZ(true)

#Nouvelle fonction qui réunis toutes les heuristique, le MTZ et le LSP
testHeuristicVRP(t=3, choice=2, heuristicExtraParam=[], useLSP=false, showMTZ=0)



