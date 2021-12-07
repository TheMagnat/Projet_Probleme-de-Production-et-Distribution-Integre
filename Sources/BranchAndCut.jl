
include("PDI_exact_resolution.jl")

include("InstanceLoader.jl")

INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"

function BranchAndCutPDI()

	params, nodes, demands, costs = readPRP(INSTANCE_PATH)

	model = createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)


	# function userSep(c_data)
	# 	#x[i=0:n, j=0:n,t=1:l]
	# 	println("#############")
	# 	println(callback_value(c_data, variable_by_name(model, "z0[0,5]")))
	# 	println("#############")
	# end


	function lazySep(c_data)
		println("#############")
		println(callback_value(c_data, variable_by_name(model, "z0[0,5]")))

		# for i in 0:params["n"]
		# 	println("I[$i, 0]: ", callback_value(c_data, variable_by_name(model, "I[$i,0]")) )
		# end

		for t=1:params["l"]

			println("y[$t]: ", callback_value(c_data, variable_by_name(model, "y[$t]")) )

			# for i=0:params["n"], j=0:params["n"]
				
			# 	if i != j
			# 		println("x[$i,$j,$t] ", callback_value(c_data, variable_by_name(model, "x[$i,$j,$t]")) )
			# 	end

			# end
		end
		println("#############")
	end

	# our userSep_ViolatedAcyclicCst function sets a LazyConstraintCallback of CPLEX   
    #MOI.set(model, MOI.UserCutCallback(), userSep)
	MOI.set(model, MOI.LazyConstraintCallback(), lazySep)

	optimize!(model)
	println("optimum = ", objective_value(model))

	for i in 1:params["l"]
		println("z0[0,$i] ", value(variable_by_name(model, "z0[0,$i]")))
	end


	# for i=0:params["n"], j=0:params["n"], t=1:params["l"]
	# 	println("x[$i,$j,$t] ", value(variable_by_name(model, "x[$i,$j,$t]")))
	# end

end


BranchAndCutPDI()