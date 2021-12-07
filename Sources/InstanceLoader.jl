
using GraphPlot
#using SimpleGraphs
#using Graphs
using OffsetArrays
#using Compose, Cairo, Fontconfig

function readPRP(filename)

	allLines = open(filename) do f
		readlines(f)
	end

	type = parse(Int, split(allLines[1], " ")[2])
	n = parse(Int, split(allLines[2], " ")[2])
	l = parse(Int, split(allLines[3], " ")[2])
	u = parse(Int, split(allLines[4], " ")[2])
	f = parse(Int, split(allLines[5], " ")[2])

	#To handle scientific notation (1e+10 for exemple)
	C = Int(parse(Float64, split(allLines[6], " ")[2]))

	Q = parse(Int, split(allLines[7], " ")[2])
	k = parse(Int, split(allLines[8], " ")[2])


	#=
		n = Nombre de revendeur (Ne comprend pas le fournisseur)
		l = Horizon de planification ( t dans {1,...,l} )
			(Les revendeurs seront fournis l fois (une fois par t))
		
		f = Cout fixe (Cout de setup), a chaque production à un temps t

		u = Cout par unité produite

		C = Capacité de production max du fournisseur ??? --> oui c'est M_t dans le PL du LSP, dans la contrainte p_t≤M_ty_t> quand y_t=1 on peut produire au max M_t=C, en fait, on considère que la capacité de production du fournisseur est infini 
		

		??? k = Nombre de véhicule de transports disponible ??? ou nombre de tournées
		Q = Capacité maximale d'un véhicule de transport
	=#
	params = Dict("type" => type, "n" => n, "l" => l, "u" => u, "f" => f, "C" => C, "Q" => Q, "k" => k)


	nextIndex = 9

	if type == 2
		mc = parse(Int, split(allLines[9], " ")[2])

		#Qu'es ce que le type 2 (B) et c'est quoi ce "mc" en plus ?
		#Les coûts sont calculés selon une formule, sur les instances de type 2, le calcul est pondérée par ce mc
		params["mc"] = mc

		nextIndex += 1
	end

	#=
	Informations du fournisseur et des revendeurs: [Fourni{}, reven_1{}, ..., reven_n{}]
		h = Cout de stockage
		L = Capacité de stockage max (capacité de stockage du fournisseur est CONSIDÉRÉ COMME INFINI)
		L0 = Stock initial 
		
		x et y (2 premières valeurs) = Coordonnées sur la "carte" des revendeurs et du fournisseur
	=#
	nodes = Vector{Dict}() #élement à l'indice i = noeud n°i

	for line in allLines[nextIndex:nextIndex+n]
		
		#Read line
		allElems = split(line, " ")


		newNode = Dict{String, Int}()
		
		newNode["initial_index"]=Int(parse(Float64, allElems[1]))
		newNode["x"] = Int(parse(Float64, allElems[2]))
		newNode["y"] = Int(parse(Float64, allElems[3]))

		#Tous les éléments d'indice impair de la ligne line en commençant par l'élément d'indice 5
		for i in filter(isodd, eachindex(allElems[5:end])) .+ 4 #[5, 7, 9]
			newNode[allElems[i]] = Int(parse(Float64, allElems[i+1]))
		end
		#=
		Equivalent à :
			newNode["h"]=Int(parse(Float64, allElems[6])) #h
			newNode["L"]]=Int(parse(Float64, allElems[7])) #L
			newNode["L0"]=Int(parse(Float64, allElems[8])) #L0
		=#

		push!(nodes, newNode)

	end

	#0 based index nodes, more coherent with the project
	nodes = OffsetVector(nodes, 0:(size(nodes)[1] - 1))

	nextIndex = nextIndex+n+2

	#=
	d_it:
		Demandes des revendeurs i au temps t.
	=#
	demands = Array{Int, 2}(undef, n, l)#élement à l'indice i,t = demande du revendeur n°i au pas de temps t

	for (i, line) in enumerate(allLines[nextIndex:nextIndex+n-1])

		cost = Vector{Int}()

		for elem in split(line, " ")[2:end]

			#Pour eviter une erreur avec les fins de lignes
			if cmp("", elem) == 0
				continue
			end

			push!(cost, Int(parse(Float64, elem)) )
		end

		
		demands[i, 1:end] = cost

	end

	#=
	c_ij:
		Cout de transport du noeud i vers le noeud j
		(exemple: transportFee[(1, 2)] -> Cout du noeud 1 vers le 2)
	=#
	transportFee = Dict{Tuple{Int, Int}, Float64}()

	#Le type determine la fonction cout
	if type == 1
		costFunc = (x1, y1, x2, y2) -> floor(1/2 + sqrt( (x1 - x2)^2 + (y1 - y2)^2 ))
	elseif type == 2
		costFunc = (x1, y1, x2, y2) -> mc * sqrt( (x1 - x2)^2 + (y1 - y2)^2 )
	end


	for i in 0:(n - 1)
		for j in (i + 1):n

			xi=nodes[i]["x"]
			yi=nodes[i]["y"]
			xj=nodes[j]["x"]
			yj=nodes[j]["y"]
			transportFee[(i, j)] = costFunc(xi, yi, xj, yj)

			#Graphe Orienté Complet
			transportFee[(j, i)] = transportFee[(i,j)]

		end
	end
	
	return params, nodes, demands, transportFee
	
end

# function generateGraphComplet(nodes)

#     g=SimpleDiGraph(length(nodes))	 # Creation of a directed graph with 1 node

# 	for i in 0:length(nodes)-1
# 		for j in 0:length(nodes)-1

# 			if(i!=j)
# 				add_edge!(g,i,j)
# 			end

# 		end
# 	end

#     return g

# end

# function generateGraph(nodes,edges)

#     g=SimpleDiGraph(length(nodes))	 # Creation of a directed graph with 1 node

# 	for (node1,node2) in edges
# 		add_edge!(g,node1,node2)
# 	end

#     return g

# end

# function generateGraphPDF(destination_file_name, file_name, graph)
# 	nodesize = [Graphs.outdegree(graph, v) for v in Graphs.vertices(graph)] #Gérer la taille des noeuds
# 	layout = (args...)->spring_layout(args...; C=20) #Gérer l'espacement des noeuds
# 	draw(PDF(destination_file_name*"/"*file_name, 16, 16), gplot(graph, nodesize=nodesize, layout=layout, EDGELINEWIDTH=0.01))
# end

