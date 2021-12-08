
#To show plot in browser
#using Gadfly


#To save plot as png
using Compose

#To plot graph
using Cairo, Fontconfig
using GraphPlot


#To create graphs
using Graphs
using Colors

function saveGraph(g, params, savePath, edgeMembership)

	#G = LightGraphs.SimpleGraph(g)

	colorsList = [RGBA(0, 0.2*(t-1), 0.1667*t, 1) for t in 1:params["l"]]

	colors = [colorsList[i] for i in edgeMembership]


	#Png
	draw(PNG(savePath, 8cm, 8cm), gplot(g, nodelabel=0:params["n"], edgestrokec=colors))

	#Web
	#gplot(g)
end


function saveCircuits(params, circuits, savePath)
	g = Graph(params["n"] + 1)

	edgeMembership = Int64[]

	currentIndex = 1

	for circuit in circuits

		for (i, j) in zip(circuit[1:end-1], circuit[2:end])
			add_edge!(g, i+1, j+1)
			push!(edgeMembership, currentIndex)
		end

		add_edge!(g, circuit[end]+1, circuit[1]+1)
		push!(edgeMembership, currentIndex)

	end

	saveGraph(g, params, savePath, edgeMembership)

end


function saveMultiCircuits(params, multiCircuits, savePath)

	g = Graph(params["n"] + 1)

	edgeMembership = Int64[]

	edgeToId = Dict{Tuple{Int, Int}, Int}()

	for (currentIndex, circuits) in enumerate(multiCircuits)

		for circuit in circuits

			for (i, j) in zip(circuit[1:end-1], circuit[2:end])
				if add_edge!(g, i+1, j+1)
					edgeToId[(i+1, j+1)] = currentIndex
					edgeToId[(j+1, i+1)] = currentIndex
				# else
				# 	edgeToId[(i+1, j+1)] += 1
				# 	edgeToId[(j+1, i+1)] += 1
				end
			end

			if add_edge!(g, circuit[end]+1, circuit[1]+1)
				edgeToId[(circuit[end]+1, circuit[1]+1)] = currentIndex
				edgeToId[(circuit[1]+1, circuit[end]+1)] = currentIndex
			# else
			# 	edgeToId[(circuit[end]+1, circuit[1]+1)] += 1
			# 	edgeToId[(circuit[1]+1, circuit[end]+1)] += 1
			end

		end

	end

	
	for e in edges(g)
		push!(edgeMembership, edgeToId[src(e), dst(e)])
		#edgeMembership
	end


	saveGraph(g, params, savePath, edgeMembership)

end


