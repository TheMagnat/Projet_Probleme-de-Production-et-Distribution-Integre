
using LightGraphs, SimpleWeightedGraphs
using OffsetArrays

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

		??? C = Capacité de production max du fournisseur ???
		

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
		L = Capacité de stockage max
		L0 = Capacité de stockage initiale
		
		??? 2 première valeur x et y ?  ???
		--> oui, ce sont les coordonnées sur la "carte" des revendeurs et du fournisseur
	=#
	nodes = Vector{Dict}() #élement à l'indice i = noeud n°i

	for line in allLines[nextIndex:nextIndex+n]
		
		#Read line
		allElems = split(line, " ")


		newNode = Dict{String, Int}()

		newNode["x"] = Int(parse(Float64, allElems[2]))
		newNode["y"] = Int(parse(Float64, allElems[3]))

		#tous les éléments d'indice impair de la ligne line en commençant par l'élément d'indice 5
		#isodd built in function that tests if x is odd
		for i in filter(isodd, eachindex(allElems[5:end])) .+ 4 #[5,7,9]
			newNode[allElems[i]] = Int(parse(Float64, allElems[i+1]))
		end
		#=
		Equivalent à :
			newNode[5]=Int(parse(Float64, allElems[6])) #h
			newNode[7]]=Int(parse(Float64, allElems[7])) #L
			newNode[9]=Int(parse(Float64, allElems[8])) #L0
		=#

		push!(nodes, newNode)

	end

	nextIndex = nextIndex+n+2

	#=
	d_it:
		Demandes des revendeurs i au temps t.
	=#
	demands = Vector{Array}() #élement à l'indice i = demande du revendeur n°i

	for line in allLines[nextIndex:nextIndex+n-1]

		cost = Vector{Int}()

		for elem in split(line, " ")[2:end]

			if cmp("", elem) == 0 # pourquoi tu testes si l'élément n'est pas un string vide?
				continue
			end

			push!(cost, Int(parse(Float64, elem)) )
		end

		push!(demands, cost)

	end

	coutEntreDeuxNoeuds=Dict{(Int,Int),Float64}()
	if type == 1
		for i in 1:size(nodes)-1
			for j in i+1:size(nodes)
				xi=nodes[i]["x"]
				yi=nodes[i]["y"]
				xj=nodes[j]["x"]
				yj=nodes[j]["y"]
				coutEntreDeuxNoeuds[(i,j)]=floor(1/2+sqrt((xi-xj)^2+(yi-yj)^2))
			end
		end
	if type == 2
		for i in 1:size(nodes)-1
			for j in i+1:size(nodes)
				xi=nodes[i]["x"]
				yi=nodes[i]["y"]
				xj=nodes[j]["x"]
				yj=nodes[j]["y"]
				coutEntreDeuxNoeuds[(i,j)]=mc*sqrt((xi-xj)^2+(yi-yj)^2)
			end
		end



	#0 based index nodes, more coherent with the project
	return params, OffsetVector(nodes, 0:(size(nodes)[1] - 1)), demands,coutEntreDeuxNoeuds

	#1 based index nodes
	#return params, nodes, demands

end


function generateGraph(params, nodes, demands)
	#Code pour faire un graph
	# for (i,line) in enumerate(eachline(f))

	# 	x = split(line," ") # For each line of the file, splitted using space as separator

	# 	if(x[1]=="p")       # A line beginning with a 'p' gives the graph size
	# 		n = parse(Int,x[3])
	# 		g = SimpleWeightedGraph(n)  # Recreation of a undirected graph with n nodes
	# 	elseif(x[1] == "e") # A line beginning with a 'e' gives the edges
	# 		v_1 = parse(Int, x[2])
	# 		v_2 = parse(Int, x[3])
	# 		add_edge!(g,v_1,v_2)
	# 		g.weights[v_1,v_2] = 1  # without edge weight
	# 	end
	# end
end


#Exemple A
#params, nodes, demands = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")

#println(nodes[0])

#Exemple B
#readPRP("../PRP_instances/B_200_instance20.prp")

