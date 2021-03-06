using Base.Iterators
using LinearAlgebra

include("Helper.jl")

function binPacking(params, nodes, demands, costs, t)

	Q = params["Q"]
	cumsum = 0


	circuits = Vector{Int64}[]

	#circuit = Vector{Int64}()
	circuit = [0]

	for (i, demand) in enumerate(demands[:, t]) #Itérer sur les demandes au temps t

		cumsum += demand

		if cumsum > Q
			push!(circuits, circuit)

			#Reset
			cumsum = demand
			circuit = [0]
		end

		push!(circuit, i)

	end

	if length(circuit) > 1
		push!(circuits, circuit)
	end

	return circuits

end

#=
Retourne une liste de tournées qui vérifie la contrainte de poids sur les véhicules
Le nombre de tournée peut toutefois excéder le nombre de véhicules disponible.

Note: Version plus rapide mais qui prend un peu plus de mémoire
=#
function clark_wright(params,nodes,demands,costs,t)

	n = params["n"]
	Q = params["Q"]

	#Initialiser S
	S = [[0, i] for i in 1:n]
	whereIs = Dict(i => circuit for (i, circuit) in enumerate(S))

	#Calcul des s_{i,j} et mettre dans l'ordre décroissant
	s=[]
	for i in 1:n, j in 1:n
		if i != j
			push!(s, [ (i,j), costs[(0, i)] + costs[(0, j)] - costs[(i, j)] ])
		end
	end
	
	sort!(s, by = x->x[2], rev=true) #by = key pour sort, rev = reverse (ordre décroissant)

	#Construction des circuits (attention il peut en avoir plus de m (le nombre de camion disponible))
	for k in 1:length(s)

		i=s[k][1][1]
		j=s[k][1][2]

		circuit_i = whereIs[i]
		circuit_j = whereIs[j]

		#Si i et j ne sont pas dans le même circuit
		if circuit_j != circuit_i

			index_circuit_i = findfirst(item -> item == circuit_i, S)
			index_circuit_j = findfirst(item -> item == circuit_j, S)

			circuit_union = union(S[index_circuit_i], S[index_circuit_j])

			#Calcul demande du nouveau circuit circuit_union
			demandeUnion=0 
			for l in circuit_union[2:end] #commence à 2 car le premier noeud du circuit est 0 (le dépot n'a pas de demande)
				demandeUnion += demands[l, t]
			end

			#Si la demande du nouveau circuit n'est pas trop pour un seul camion
			if demandeUnion <= Q
				
				deleteat!(S, sort!([index_circuit_i, index_circuit_j]))

				push!(S, circuit_union)


				for index in circuit_union
					push!(whereIs, index=>circuit_union)
				end

			end
		end

	end

	return S #la liste des circuits qui sont des tournées valides (qui respectent la contrainte de poids)
end


#=
Retourne une liste de tournées qui vérifie la contrainte de poids sur les véhicules
Le nombre de tournée peut toutefois excéder le nombre de véhicules disponible.

Note: Version plus lente mais qui prend un peu moins de mémoire
=#
function clark_wright_old(params,nodes,demands,costs,t)
	
	n = params["n"]
	Q = params["Q"]

	#Initialiser S
	S = [[0, i] for i in 1:n]
	

	#Calcul des s_{i,j} et mettre dans l'ordre décroissant
	s=[]
	for (i,j) in product(1:n,1:n)
		if i != j
			push!(s,[(i,j),costs[(0,i)]+costs[(0,j)]-costs[(i,j)]])
		end
	end
	sort!(s, by = x->x[2], rev=true) #by = key pour sort, rev = reverse (ordre décroissant)

	#Construction des circuits (attention il peut en avoir plus de m (le nombre de camion disponible))
	for k in 1:length(s)

		i=s[k][1][1]
		j=s[k][1][2]
		foundi=false
		foundj=false
		circuit_i=NaN
		circuit_j=NaN
		index_i=0
		index_j=0

		#trouver les circuits où sont i et j
		for (index, circuit) in enumerate(S)
			if i in circuit
				circuit_i=circuit
				foundi=true
				index_i = index
			end
			if j in circuit
				circuit_j=circuit
				foundj=true
				index_j = index
			end
			if foundi && foundj
				break
			end
		end

		#Si i et j ne sont pas dans le même circuit
		if circuit_j != circuit_i

			#création de l'union de circuit_i et circuit_j
			circuit_union=union(circuit_i, circuit_j)

			#Calcul demande du nouveau circuit circuit_union
			demandeUnion=0 
			for l in 2:length(circuit_union) #commence à 2 car le premier noeud du circuit est 0 (le dépot n'a pas de demande)
				demandeUnion+=demands[circuit_union[l],t]
			end

			#Si la demande du nouveau circuit n'est pas trop pour un seul camion
			if demandeUnion<=Q
				#suppression des circuits circuit_i et circuit_j
				deleteat!(S, sort!([index_i, index_j]))

				push!(S,circuit_union) 
			end
		end
	end

	return S #la liste des circuits qui sont des tournées valides (qui respectent la contrainte de poids)
end


function sectorielle(params, nodes, demands, costs, t, angle)

	parts = div(360, angle)
	angle = 360 / parts

	center = [nodes[0]["y"], nodes[0]["x"]]
	top = [1, 0]


	sectors = [Int[] for i in 1:parts]

	for (i, node) in enumerate(nodes[1:end])
		centredPoint = [node["y"], node["x"]] - center

		#Calcul du degré entre le vecteur directionnel [1, 0] et le vecteur centre vers le point
		degree = mod(rad2deg(atan(top...) - atan(centredPoint...)), 360)

		index = Int( div(degree, angle) ) % parts + 1

		push!(sectors[index], i)
	end

	Q = params["Q"]

	circuits = Vector{Int64}[]
	circuit = [0]
	cumsum = 0

	for sector in sectors
		for i in sector

			demand = demands[i, t]
			cumsum += demand

			if cumsum > Q
				push!(circuits, circuit)

				#Reset
				cumsum = demand
				circuit = [0]
			end

			push!(circuit, i)

		end
	end

	if length(circuit) > 1
		push!(circuits, circuit)
	end


	return circuits

end

#=
Reorder the circuit by putting the value (currtently at pos) at the first index
=#
function replace(circuit, pos)

	return vcat(circuit[pos:end], circuit[1:pos-1])

end

function TSPVoisins(circuit)

	n = length(circuit)

	voisins = Vector{Int64}[]

	for i in 1:n
		for j in i+1:n
			voisin = copy(circuit)
			voisin[i], voisin[j] = voisin[j], voisin[i]

			if i == 1
				voisin = replace(voisin, j)
			end
			push!(voisins, voisin)
		end
	end

	return voisins

end

function TSPBoost(circuits, params, costs)

	for (i, circuit) in enumerate(circuits)

		best = circuit
		bestCost = getCircuitCost(circuit, costs)

		while true

			voisins = TSPVoisins(best)
			noChange = true

			for voisin in voisins
				cost = getCircuitCost(voisin, costs)

				if cost < bestCost
					bestCost = cost
					best = voisin
					noChange = false
				end

			end

			if noChange
				break
			end

		end


		circuits[i] = best

	end

	return circuits

end


function SwapCircuitVoisins(circuits)

	voisins = Vector{Vector{Int64}}[]

	for (i, circuit) in enumerate(circuits)
		for (j, elem) in enumerate(circuit[2:end])

			j += 1

			for indexCircuit in 1:length(circuits)
				if i != indexCircuit
					voisin = deepcopy(circuits)

					deleteat!(voisin[i], j)
					push!(voisin[indexCircuit], elem)

					#If only zero remain in i
					if length(voisin[i]) == 1
						deleteat!(voisin, i)
					end

					push!(voisins, voisin)
				end
			end

		end
	end

	return voisins

end

#=

Métaheuristique faisant:
	- Ajout d'un circuit vide si possible

	Voisin:
		- Déplace chaque noeud de chaque circuit à la fin de chaque autre circuit
		- Suppression du circuit vide si il l'est encore
		- Appliquer la recherche local de TSP sur chaque circuit de chaque voisin

=#
function mixMetaheuristic(circuits, params, costs)

	###Initiliaze

	#Deep copy pour ne pas modifier circuits de base
	currentCircuits = deepcopy(circuits)
	currentCircuits = TSPBoost(currentCircuits, params, costs)

	#Noeud courant est le meilleur actuellement
	best = deepcopy(currentCircuits)
	bestCost = getCircuitsCost(best, costs)

	while true
		#Debug
		#println("Loop ", bestCost)

		###Creation des voisins

		#Ajouter un circuit vide si le nombre n'est pas déjà dépassé
		if length(best) < params["k"]
			push!(best, [0])
		end

		voisins = SwapCircuitVoisins(best)

		#Retirer les 0 les circuits contenant seulement 0 et de best (-1 car on rajouté 1 avant)
		if length(best) - 1 < params["k"]

			pop!(best)

			for voisin in voisins
				if length(voisin[end]) == 1
					pop!(voisin)
				end
			end

		end

		#Appliquer la recherche locale de TSP
		for voisin in voisins

			voisin = TSPBoost(voisin, params, costs)
		end

		###Fin de création des voisins

		noChange = true

		#Trouver le meilleur voisin
		for voisin in voisins
			cost = getCircuitsCost(voisin, costs)

			if cost < bestCost

				bestCost = cost
				best = voisin
				noChange = false

			end

		end

		if noChange
			break
		end

	end

	return best

end

#=
function sectorielle_old(params,nodes,demands,costs,t,angle) #ON SUPPOSE QUE 360 EST DIVISIBLE PAR ANGLE (sinon trop compliqué, flemme)
	distance_du_point_le_plus_eloigne=0
	origin=nodes[0]
	#Calcul de la distance du point le plus eloigné
	for node in nodes
		distance=sqrt((node["x"]-origin["x"])^2+(node["y"]-origin["y"])^2)
		if(distance_du_point_le_plus_eloigne<distance)
			distance_du_point_le_plus_eloigne=distance
		end
	end

	
	#Calcul distance point fictif a l'origine
		#La distance de ces points fictif à l'origine ne peut pas être égale 
		#a la distance du point le plus eloigné car celui ci peut ne pas être aucun des triangles
		#C'est pourquoi que la distance des points fictifs à l'origine sera égal à
		#la somme de la distance du point le plus eloigné + la distance entre le (point D qui est le point au milieu
		# du segment entre deux points fictifs quelconquz) et le
		#(point E de fin du segment qui commence à l'origine, passant par D ) 

	distance_point_fictif_a_lorigine=distance_du_point_le_plus_eloigne*(2-cos(angle/2))

	#Création des points fictifs pour créer les secteurs en triangles
	angleNormalise=angle/360
	triangles=[]
	for i in 1:360/angle
		push!(triangles,[(float(origin["x"]),float(origin["y"]))])
	end
	k=1
	for i in 1:2*360/angle
		point=(origin["x"]+(1-(i-1)*angleNormalise)*distance_point_fictif_a_lorigine,origin["y"]+(i-1)*angleNormalise*distance_point_fictif_a_lorigine)
		push!(triangles[k],point)
		k+=Integer((i+1)%2)
	end

	#Création secteurs (il y en a 360/angle)
	secteurs=[]
	for i in 1:length(triangles)
		push!(secteurs,[origin])
	end
	initial=true
	for node in nodes
		if initial
			initial=false
			continue
		end
		k=1
		for (Ori,A,B) in triangles #detection de quel secteur est situé le point
			# AB=vecteurEntreDeuxPoints(A,B)
			# BA=vecteurEntreDeuxPoints(B,A)

			# OriA=vecteurEntreDeuxPoints(Ori,A)
			# AOri=vecteurEntreDeuxPoints(A,Ori)
			
			# OriB=vecteurEntreDeuxPoints(Ori,B)
			# BOri=vecteurEntreDeuxPoints(B,Ori)
			
			# ANode=vecteurEntreDeuxPoints(A,(node["x"],node["y"]))
			# BNode=vecteurEntreDeuxPoints(B,(node["x"],node["y"]))
			# OriNode=vecteurEntreDeuxPoints(C,(node["x"],node["y"]))
			
			# #print(AB,BA,OriA,AOri,OriB,BOri,ANode,BNode,OriNode)
			# if dot(cross(AB,ANode),cross(ANode,AOri))>=0 && dot(cross(BA,BNode),cross(BNode,BOri))>=0 && dot(cross(OriA,OriNode),cross(OriNode,OriB))>=0
			# 	push!(secteurs[k],node)
			# 	break
			# end

			cond1=(A[1]-node["x"])*(B[2]-node["y"])-(A[2]-node["y"])*(B[1]-node["x"])
			cond2=(B[1]-node["x"])*(Ori[2]-node["y"])-(B[2]-node["y"])*(Ori[1]-node["x"])
			cond3=(Ori[1]-node["x"])*(A[2]-node["y"])-(Ori[2]-node["y"])*(A[1]-node["x"])
			if((cond1>=0 && cond2>=0 && cond3>=0) || (cond1<0 && cond2<0 && cond3<0))
				push!(secteurs[k],node)
				break
			end
			k+=1
		end
	end

	ens_de_ens_de_circuits=[]
	for secteur in secteurs
		push!(ens_de_ens_de_circuits,clark_wright(params,secteur,demands,costs,t))
	end

	ens_final=[]
	for ens_de_circuits in ens_de_ens_de_circuits
		for circuit in ens_de_circuits
			push!(ens_final,circuit)
		end
	end
	return ens_final
end

=#