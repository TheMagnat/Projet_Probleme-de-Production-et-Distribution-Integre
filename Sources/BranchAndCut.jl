
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
		# println("#############")
		# println(callback_value(c_data, variable_by_name(model, "z0[0,5]")))

		# for i in 0:params["n"]
		# 	println("I[$i, 0]: ", callback_value(c_data, variable_by_name(model, "I[$i,0]")) )
		# end

		n = params["n"]
		l = params["l"]
		Q = params["Q"]

		for t=1:l

			#println("y[$t]: ", callback_value(c_data, variable_by_name(model, "y[$t]")) )


			fullHisto = Set{Int64}()
			sousTours = Set{Int64}[]


			for i in 1:n

				#Si noeud pas déjà dans un circuit trouvé
				if !( i in fullHisto ) && ( round( callback_value(c_data, variable_by_name(model, "z[$i,$t]")) ) == 1 )

					foundZero = false

					current = i

					##Initiliser historique avec i
					histo = Set{Int64}(current)
					#push!(histo, current)

					##Pour faire les deux sens
					##INUTILE ENFAIT
					#for reverse in range 1:2

					while true

						#On cherche le noeud précédent
						for j in 0:n
							if current != j
								
								#Si on trouve le noeud précédent
								if round( callback_value(c_data, variable_by_name(model, "x[$j,$current,$t]")) ) == 1
									current = j
									break
								end

							end
						end

						#Fin du circuit avec passage en 0
						if current == 0
							foundZero = true
							break
						end

						#Fin du circuit mais pas de passage en 0
						if current in histo
							break
						end

						push!(histo, current)

					end

					#Si pas de zero trouvé, sous-tour
					if !foundZero
						push!(sousTours, histo)
					end

					#Ajouter le cycle trouver a l'historique pour ne pas refaire l'algorithme dessus
					fullHisto = union(fullHisto, histo)

				end
			end

			#Set complet
			fullSet = Set(0:n)

			for sousTour in sousTours

				#Set sans le sous tour
				setNotInSousTour = setdiff(fullSet, sousTour)

				con = @build_constraint(sum( variable_by_name(model, "x[$i,$j,$t]") for i in setNotInSousTour, j in sousTour) >= sum( variable_by_name(model, "q[$i,$t]") for i in sousTour)/Q )
				
				MOI.submit(model, MOI.LazyConstraint(c_data), con)

				#Pour user cut
				#MOI.submit(LP, MOI.UserCut(cb_data), con) 
			end


		end

	end

	# our userSep_ViolatedAcyclicCst function sets a LazyConstraintCallback of CPLEX   
    #MOI.set(model, MOI.UserCutCallback(), userSep)
	MOI.set(model, MOI.LazyConstraintCallback(), lazySep)

	optimize!(model)
	println("optimum = ", objective_value(model))

	for i in 1:params["l"]
		println("z0[0,$i] ", value(variable_by_name(model, "z0[0,$i]")))
	end


	# for i=0:params["n"], j=0:params["n"], t=1:l
	# 	println("x[$i,$j,$t] ", value(variable_by_name(model, "x[$i,$j,$t]")))
	# end

end


BranchAndCutPDI()