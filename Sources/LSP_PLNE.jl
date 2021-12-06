using JuMP
using CPLEX
#using GLPK

function createLSP(params, nodes, demands, costs)

	#model = Model(GLPK.Optimizer)
	model = Model(CPLEX.Optimizer)

	#= Paramètres (Constantes) du problème

		demands[i][t] : d_{i,t}= demande du revendeur i au pas de temps t | i in [1,n], t in [1,l]=T 
		nodes[i]["h"] : h_i = coût de stockage d'un produit pour le revendeur/fournisseur i | i in [0,n]
		node[i]["L"] : L_i le stock maximal du revendeur/fournisseur i | i in [0,n]
		params["u"] : u = coût de production d'un produit pour le fournisseur
		params["f"] : f = coût de set up (pour chaque période où le fournisseur décide de produire, il paye un coût f)
		params["C"] : C = Capacité de production max du fournisseur (=M dans le sujet)

	=#

	#= Variables de décision
		
		p[t] : p_t  (Variable de production): quantité produite à la période t
		y[t] : y_t  (Variable de lancement): variable binaire qui vaut 1 si une production est lancée à la période t, et 0 sinon

		I[i,j] : I_{i,t} (Variable de stockage): quantité en stock à la fin de la période t pour i.
		
		q[i,j] : q_{i,t} (Variable d’approvisionnement): quantité produite pour le revendeur i à la période t.

	=#

	#Variables Réel positive
	@variable(model, p[1:params["l"]] >= 0)
	@variable(model, I[0:params["n"], 0:params["l"]] >= 0)
	@variable(model, q[1:params["n"], 1:params["l"]] >= 0)

	#Variable binaire
	@variable(model, y[1:params["l"]], Bin)


	for i in 0:params["n"]
		@constraint(model, I[i, 0] == nodes[i]["L0"])
	end


	###Fonction objectif

	obj = 0
	for t in 1:params["l"]

		#On ajoute le cout de production de touts les produits au temps t
		obj += params["u"] * p[t]

		#Si on produit au temps t, on ajoute le cout de setup
		obj += params["f"] * y[t]

		#??? On ne prend pas le cout de stockage de fournisseur ?
		for i in 1:params["n"]
			obj += nodes[i]["h"] * I[i, t]
		end

	end
	@objective(model, Min, obj)

	###Contraintes
	for t in 1:params["l"]

		@constraint(model, I[0, t-1] + p[t] == I[0, t] + sum(q[i, t] for i in 1:params["n"])) #contraintes 1

		for i in 1:params["n"]
			@constraint(model, I[i, t-1] + q[i, t] == demands[i, t] + I[i, t]) #contraintes 2
			@constraint(model, I[i, t-1] + q[i, t] <= nodes[i]["L"]) #contraintes 5
		end

		@constraint(model, p[t] <= params["C"] * y[t]) #constraintes 3
		@constraint(model, I[0, t-1] <= nodes[0]["L"]) #contraintes 4

	end
	
	return model

end
