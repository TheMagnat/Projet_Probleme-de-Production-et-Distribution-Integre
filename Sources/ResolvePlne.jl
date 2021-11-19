using JuMP
using Dates

const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE


function resolvePlne(model, verbose=1, nameOfPL="")

	optimize!(model)

	if verbose == 3
		println(solution_summary(model, verbose=true))
		return model
	end

	status = termination_status(model)

	# if status == JuMP.MathOptInterface.OPTIMAL
	# 	println("Valeur optimale = ", objective_value(model))
	# end


	if verbose >= 2

		last = ""
		for var in all_variables(model)

			which = split(JuMP.name(var), "[")[1]
			if which != last
				last = which
				println("\nVariables $(last)")
			end
			println(var, ": ", value(var))

		end

	end

	if verbose >= 1
		println("\nObjetive value: ", objective_value(model))
	end

	if ! isempty(nameOfPL) 
		write_to_file(model, nameOfPL*"_model_"*string(Dates.now())*".mps")
	end

	return model

end

function getModelVariables(model)
	
end

