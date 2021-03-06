
include("PDI_exact_resolution.jl")

include("InstanceLoader.jl")
include("Helper.jl")
include("GraphHelper.jl")

INSTANCE_PATH = "../PRP_instances/A_014_#ABS1_15_1.prp"
#INSTANCE_PATH = "../PRP_instances/A_050_ABS14_50_1.prp"

function BranchAndCutPDI(params, nodes, demands, costs)

	model = createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)


	function lazySep(c_data)

		n = params["n"]
		l = params["l"]
		Q = params["Q"]

		for t=1:l

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

				#FCCs
				if length(sousTour)>=1
					con = @build_constraint(sum( variable_by_name(model, "x[$i,$j,$t]") for i in setNotInSousTour, j in sousTour) >= sum( variable_by_name(model, "q[$i,$t]") for i in sousTour)/Q )
					MOI.submit(model, MOI.LazyConstraint(c_data), con)
				end

				#FCCs Reversed Q
				#con = @build_constraint(Q * sum( variable_by_name(model, "x[$i,$j,$t]") for i in setNotInSousTour, j in sousTour) >= sum( variable_by_name(model, "q[$i,$t]") for i in sousTour) )
				#MOI.submit(model, MOI.LazyConstraint(c_data), con)

				#GFSECs
				#if length(sousTour)>=2
					#con = @build_constraint(sum( i != j ? variable_by_name(model, "x[$i,$j,$t]") : 0 for i in sousTour, j in sousTour) <= length(sousTour) - sum( variable_by_name(model, "q[$i,$t]") for i in sousTour)/Q )
					#MOI.submit(model, MOI.LazyConstraint(c_data), con)
				#end
				#GFSECs Reversed Q by Adulyasak
				#if length(sousTour)>=2
				#con = @build_constraint( Q * sum( i != j ? variable_by_name(model, "x[$i,$j,$t]") : 0 for i in sousTour, j in sousTour) <= sum(Q*variable_by_name(model, "z[$i,$t]") - variable_by_name(model, "q[$i,$t]") for i in sousTour) )
				#MOI.submit(model, MOI.LazyConstraint(c_data), con)
				#end

				#Pour user cut
				#MOI.submit(LP, MOI.UserCut(cb_data), con) 
			end

		end
	end

	#Mauvais algorithme
	#=
	function userSep(c_data)

		n = params["n"]
		l = params["l"]
		Q = params["Q"]

		for t=1:l

			fullHisto = Set{Int64}()
			sousTours = Set{Int64}[]

			for i in 1:n

				#Si noeud pas déjà dans un circuit trouvé
				if !( i in fullHisto ) && ( callback_value(c_data, variable_by_name(model, "z[$i,$t]")) > 0 )

					# println("z[$i,$t]", callback_value(c_data, variable_by_name(model, "z[$i,$t]")))
					###DEBUG
					
					# for j in 0:n
					# 	if i != j
					# 		println("x[$j,$i,$t]", callback_value(c_data, variable_by_name(model, "x[$j,$i,$t]")))
					# 	end
					# end
					# continue

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
								if callback_value(c_data, variable_by_name(model, "x[$j,$current,$t]")) > 0
									current = j
									break
								end

							end
						end

						#Fin du circuit avec passage en 0
						if current == 0
							#println("ZERO")
							foundZero = true
							break
						end

						#Fin du circuit mais pas de passage en 0
						if current in histo
							#println("DANS HISTO")
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

				#con = @build_constraint(sum( variable_by_name(model, "x[$i,$j,$t]") for i in setNotInSousTour, j in sousTour) >= sum( variable_by_name(model, "q[$i,$t]") for i in sousTour)/Q )
				#MOI.submit(model, MOI.UserCut(c_data), con)

				con = @build_constraint( Q * sum( i != j ? variable_by_name(model, "x[$i,$j,$t]") : 0 for i in sousTour, j in sousTour) <= sum(Q*variable_by_name(model, "z[$i,$t]") - variable_by_name(model, "q[$i,$t]") for i in sousTour) )
				MOI.submit(model, MOI.UserCut(c_data), con)
				
			end

		end

	end
	=#

	# our userSep_ViolatedAcyclicCst function sets a LazyConstraintCallback of CPLEX   
	MOI.set(model, MOI.LazyConstraintCallback(), lazySep)

	#MOI.set(model, MOI.UserCutCallback(), userSep)
	#set_time_limit_sec(model,10800) #time limit de 3h
	optimize!(model)

	return model
end


function PDItoCircuits(model, params, nodes, demands, costs)

	allCircuits = []

	for t in 1:params["l"]
		push!(allCircuits, vrpToCircuit(model, params, true, t))
	end

	return allCircuits

end
