
include("PDI_exact_resolution.jl")

include("InstanceLoader.jl")

INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"

function BranchAndCutPDI()

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)


	function userSep(c_data)
		#x[i=0:n, j=0:n,t=1:l]
		println("#############")
		println(callback_value(c_data, variable_by_name(model, "z0[0,5]")))
		println("#############")
	end


	# our userSep_ViolatedAcyclicCst function sets a LazyConstraintCallback of CPLEX   
    MOI.set(model, MOI.UserCutCallback(), userSep)


	optimize!(model)
	println("optimum = ", objective_value(model))

	# for i in 1:params["l"]
	# 	println("z0[0,$i] ", value(variable_by_name(model, "z0[0,$i]")))
	# end

	# for i in 1:params["l"]
	# 	println("z0[0,$i] ", value(variable_by_name(model, "z0[0,$i]")))
	# end

	# for i=0:params["n"], j=0:params["n"], t=1:params["l"]
	# 	println("x[$i,$j,$t] ", value(variable_by_name(model, "x[$i,$j,$t]")))
	# end

end


BranchAndCutPDI()