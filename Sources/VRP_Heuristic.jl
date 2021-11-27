

function binPacking(params, nodes, demands, costs, t)

	Q = params["Q"]
	cumsum = 0


	allTour = Vector{Int64}[]

	#currentTour = Vector{Int64}()
	currentTour = [0]

	for (i, demand) in enumerate(demands[:, t])

		cumsum += demand

		if cumsum > Q
			push!(currentTour, 0)
			push!(allTour, currentTour)

			#Reset
			cumsum = demand
			#currentTour = Vector{Int64}()
			currentTour = [0]
		end

		push!(currentTour, i)

		

	end

	push!(currentTour, 0)
	push!(allTour, currentTour)

	#AFFICHAGE
	print(allTour)

end