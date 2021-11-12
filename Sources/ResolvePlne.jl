using JuMP
using Dates

const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE

#For exemples
include("LSP_PLNE.jl")
include("VRP_PLNE.jl")
include("InstanceLoader.jl")

function resolvePlne(model, showVar=true, nameOfPL="")

	optimize!(model)

	println(solution_summary(model, verbose=true))
	status = termination_status(model)

	if status == JuMP.MathOptInterface.OPTIMAL
		println("Valeur optimale = ", objective_value(model))
	end


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

	write_to_file(model, nameOfPL*"_model_"*string(Dates.now())*".mps")

	return model

<<<<<<< HEAD
#Exemple
#params, nodes, demands, costs = readPRP("/Users/davidpinaud/GitHub/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_#ABS1_15_1.prp")
params, nodes, demands, costs = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")
#model = createLSP(params, nodes, demands, costs)
model = createVRP_MTZ(params, nodes, demands, costs, 1)
=======
end
>>>>>>> 2d27f329494a69433419d399456aa3d34bf1f9ac

function getModelVariables(model)
	
end
#Exemple
params, nodes, demands, costs = readPRP("/Users/david_pinaud/Desktop/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS1_15_1.prp")
#params, nodes, demands, costs = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")
#model = createLSP(params, nodes, demands, costs)
model = createVRP_MTZ(params, nodes, demands, costs, 1)
resolvePlne(model, false, "VRP")
