
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")
include("PDI_exact_resolution.jl")
include("VRP_Heuristic.jl")
include("Helper.jl")
include("PDI_heuristic_resolution.jl")

include("GraphHelper.jl")

include("BranchAndCut.jl")
include("allFiles.jl")

#Instances A

INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
#INSTANCE_PATH = "../PRP_instances/A_050_ABS12_50_3.prp"
#INSTANCE_PATH = "../PRP_instances/A_050_ABS14_50_1.prp"
#INSTANCE_PATH = "../PRP_instances/A_100_ABS5_100_4.prp"

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


function testPDI_Bard_Nananukul(solve=false, verbose=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)
	if solve
		resolvePlne(model, verbose)
	end
	return model

end

function testPDI_heuristique(resoudreVRPwithHeuristic=true, nbMaxIte=10)

	lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial=initialisation_PDI_heuristique(INSTANCE_PATH)
	lsp_model, circuits = PDI_heuristique(lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial, nbMaxIte, resoudreVRPwithHeuristic)

end




#=
t: choisir le temps sur lequel tester
choice: Choisir l'heuristique ?? utiliser
metaChoice: Choisir la m??taheuristique ?? utiliser (0 si aucune)

showCircuits: Montrer ou non les circuits des heuristiques/m??taheuristiques

useLSP: Si vrai, appliquer d'abord le LSP pour obtenir les vrai valeur de VRP

showMTZ:
	0: Ne pas montrer le r??sultat de MTZ
	1: Montrer le r??sultat de MTZ
	2: Montrer le circuit de MTZ
	3: Ne montrer que MTZ et pas l'heuristique

	ATTENTION: MTZ sur des instances de plus de 14 risque de prendre tr??s longtemps

heuristicExtraParam:
	Param??tre en plus de ceux de base pour l'heuristique (Exemple l'angle pour sectorielle)

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

function testBranchAndCutPDI(filePath)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = BranchAndCutPDI(params, nodes, demands, costs)

	println("optimum = ", objective_value(model))

	allCircuits = PDItoCircuits(model, params, nodes, demands, costs)

	saveMultiCircuits(params, allCircuits, filePath)

end


function testCompareExact(logPath)


	open(logPath, "a") do io

		t = 1

		path_to_file = "../PRP_instances/"

		for file in allFiles

			params, nodes, demands, costs = readPRP(INSTANCE_PATH)

			model, totalExactTime = @timed BranchAndCutPDI(params, nodes, demands, costs)

			exactValue = objective_value(model)

			

			resoudreVRPwithHeuristic=true
			nbMaxIte=10

			lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial=initialisation_PDI_heuristique(INSTANCE_PATH)
			(lsp_model, circuits), totalTimeHeuristic = @timed PDI_heuristique(lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial, nbMaxIte, resoudreVRPwithHeuristic)

			heuristicValue = objective_value(lsp_model)

			println("Exacte: ", exactValue)
			println("Heuristique: ", heuristicValue)

			println(io,"$file,$(exactValue),$(totalExactTime),$(heuristicValue),$(totalTimeHeuristic)")

		end #Loop file

	end #Open

end



function testLogCompareHeuristic(logPath; heuristicExtraParam=[30])
	allHeuristic = [[binPacking, "Bin packing"], [clark_wright, "Clark-Wright"], [sectorielle, "Sectorielle"]]
	allMetaheuristic = [[TSPBoost, "TSP Local search"], [mixMetaheuristic, "Mix Metaheuristic"]]

	

	# modelVRP = createVRP_MTZ(params, nodes, demands, costs, t)
	# resolvePlne(modelVRP, 0)

	# objective_value(modelVRP)

	open(logPath, "a") do io

		t = 1

		path_to_file = "../PRP_instances/"

		for file in allFiles

			params, nodes, demands, costs = readPRP(path_to_file*file)

			rez = Vector{Float64}(undef, length(allHeuristic) * length(allMetaheuristic))

			for (i, heuristic) in enumerate(allHeuristic)

				heuristicExtraParamCurrent = heuristicExtraParam

				if i < 3
					heuristicExtraParamCurrent = []
				end
				circuits = heuristic[1](params, nodes, demands, costs, t, heuristicExtraParamCurrent...)
			
				for (j, metaheuristic) in enumerate(allMetaheuristic)

					circuits = metaheuristic[1](circuits, params, costs)
					totalCost = getCircuitsCost(circuits, costs)

					#println(heuristic[2], " ", metaheuristic[2], " = ", totalCost)
					rez[i + length(allHeuristic) * (j - 1)] = totalCost

				end

			end

			println(io,"$file,$(rez[1]),$(rez[2]),$(rez[3]),$(rez[4]),$(rez[5]),$(rez[6])")

		end #Loop file

	end #Open
end


function testLogCompareMTZ_Heuristic(logPath)

	heuristic = clark_wright
	metaheuristic = mixMetaheuristic


	# modelVRP = createVRP_MTZ(params, nodes, demands, costs, t)
	# resolvePlne(modelVRP, 0)

	# objective_value(modelVRP)

	open(logPath, "a") do io

		t = 1

		path_to_file = "../PRP_instances/"

		for file in allFiles

			params, nodes, demands, costs = readPRP(path_to_file*file)


			modelVRP = createVRP_MTZ(params, nodes, demands, costs, t)
			modelVRP, totalMTZtime = @timed resolvePlne(modelVRP, 0)

			mtzVal = objective_value(modelVRP)


			
			totalTimeHeuristic = 0

			circuits, elapsedTime = @timed heuristic(params, nodes, demands, costs, t)
			totalTimeHeuristic += elapsedTime

			circuits, elapsedTime = @timed metaheuristic(circuits, params, costs)
			totalTimeHeuristic += elapsedTime

			totalCost = getCircuitsCost(circuits, costs)

			println(io,"$file,$(mtzVal),$(totalMTZtime),$(totalCost),$(totalTimeHeuristic)")

		end #Loop file

	end #Open
end

testCompareExact("pdiCompare.csv")

#testLogCompareHeuristic("metaheuristic.csv", heuristicExtraParam=[10])

#testLogCompareMTZ_Heuristic("mtz_meta.csv")

#Nouvelle fonction qui r??unis toutes les heuristique, le MTZ et le LSP

#testHeuristicVRP(t=3, choice=2, metaChoice=1, showCircuits=false, useLSP=false, heuristicExtraParam=[10], showMTZ=0, savePath="../Save/test.png")

#testHeuristicVRP(t=4, choice=2, metaChoice=1, showCircuits=false, useLSP=true, heuristicExtraParam=[10], showMTZ=0, savePath="../Save/test.png")

#testPDI_heuristique()
#testPDI_Boudia(true)
#testPDI_Bard_Nananukul(true,2)

#testBranchAndCutPDI("./Save/BAC_David.png")

