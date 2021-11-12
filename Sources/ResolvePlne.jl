using JuMP
using Dates

const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE


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

end

function getModelVariables(model)
	
end

