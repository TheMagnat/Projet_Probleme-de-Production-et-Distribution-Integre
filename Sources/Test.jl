
include("InstanceLoader.jl")
include("VRP_PLNE.jl")
include("LSP_PLNE.jl")
include("ResolvePlne.jl")


#Instances A
INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
#INSTANCE_PATH = "/Users/david_pinaud/Desktop/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS1_15_1.prp"

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
		resolvePlne(model, false, "LSP")
	end

end


function testVRP_MTZ(solve=false, t=1)

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createVRP_MTZ(params, nodes, demands, costs, t)

	if solve
		resolvePlne(model, false, "LSP")
	end

end

#testGenerateGraph()
#testLSP(true)
#testVRP_MTZ(true)

