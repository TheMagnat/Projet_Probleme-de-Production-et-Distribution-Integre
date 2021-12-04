
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")

include("VRP_Heuristic.jl")
include("Helper.jl")


#Instances A
INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
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


function testLSP_Then_VRP_MTZ()

	t = 2

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	tToVRP = getTrueVRP(params, nodes, demands, costs)

	copyParams, copyNodes, copyDemandsAtT, copyCost = tToVRP[t]
	
	modelVRP = createVRP_MTZ(copyParams, copyNodes, copyDemandsAtT, copyCost, t)
	resolvePlne(modelVRP, 1)

end

function testVRP_MTZtoCircuit(t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createVRP_MTZ(params, nodes, demands, costs, t)

	resolvePlne(model, 1)

	circuits = vrpToCircuit(model, params)

	totalCost = getCircuitsCost(circuits, costs)

	println("getCircuitsCost: ", totalCost)

end


function testBinPacking(t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	circuits = binPacking(params, nodes, demands, costs, t)

	println("Circuits: ", circuits)

	totalCost = getCircuitsCost(circuits, costs)

	println("getCircuitsCost: ", totalCost)

end

function testBinPacking2(t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)
	tToVRP = getTrueVRP(params, nodes, demands, costs)

	copyParams, copyNodes, copyDemandsAtT, copyCost = tToVRP[t]
	
	modelVRP = createVRP_MTZ(copyParams, copyNodes, copyDemandsAtT, copyCost, t)
	resolvePlne(modelVRP, 1)

	circuits = binPacking(copyParams, copyNodes, copyDemandsAtT, copyCost, t)
	println("Circuits: ", circuits)
	totalCost = getCircuitsCost(circuits, costs)
	println("getCircuitsCost: ", totalCost)

end

function test_clark_wright(t=1)
	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	circuits=clark_wright(params,nodes,demands,costs,t)

	println("Circuits: ", circuits)

	totalCost = getCircuitsCost(circuits, costs)

	println("getCircuitsCost: ", totalCost)
end

function test_sectorielle(t=1,angle=30) #angle doit être un diviseur de 360
	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	circuits=sectorielle(params,nodes,demands,costs,t,angle)

	println("Circuits: ", circuits)

	totalCost = getCircuitsCost(circuits, costs)

	println("getCircuitsCost: ", totalCost)
end

#testGenerateGraph()
#testLSP(true)
#testVRP_MTZ(true)
#testLSP_Then_VRP_MTZ()

#testBinPacking()
testBinPacking2(3)
#test_clark_wright()
#test_sectorielle()

