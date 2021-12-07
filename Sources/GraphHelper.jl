
#To show plot in browser
#using Gadfly


#To save plot as png
using Compose

#To plot graph
using Cairo, Fontconfig
using GraphPlot


#To create graphs
using Graphs

function saveGraph(g, params, savePath)

	#G = LightGraphs.SimpleGraph(g)
	#Png
	draw(PNG(savePath, 8cm, 8cm), gplot(g, nodelabel=0:params["n"]))

	#Web
	#gplot(g)
end


function saveCircuits(params, circuits, savePath)
	g = Graph(params["n"] + 1)


	for circuit in circuits

		for (i, j) in zip(circuit[1:end-1], circuit[2:end])
			add_edge!(g, i+1, j+1)
		end

		add_edge!(g, circuit[end]+1, circuit[1]+1)

	end

	saveGraph(g, params, savePath)

end



