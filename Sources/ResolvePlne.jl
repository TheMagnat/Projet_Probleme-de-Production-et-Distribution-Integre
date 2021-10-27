using JuMP

const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE

#For exemples
include("LSP_PLNE.jl")
include("VRP_PLNE.jl")
include("InstanceLoader.jl")

function resolvePlne(model, showVar=true)

	optimize!(model)

	if showVar

		last = ""
		for var in all_variables(model)

			which = split(name(var), "[")[1]
			if which != last
				last = which
				println("\nVariables $(last)")
			end
			println(var, ": ", value(var))

		end

	end

	println("\nObjetive value: ", objective_value(model))

end


#Exemple
#params, nodes, demands, costs = readPRP("/Users/davidpinaud/GitHub/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_#ABS1_15_1.prp")
params, nodes, demands, costs = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")
model = createLSP(params, nodes, demands, costs)
#model = createVRP_MTZ(params, nodes, demands, costs, 1)

resolvePlne(model, false)
