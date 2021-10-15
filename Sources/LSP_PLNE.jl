using JuMP
using GLPK

include("InstanceLoader.jl")

const OPTIMAL = JuMP.MathOptInterface.OPTIMAL
const INFEASIBLE = JuMP.MathOptInterface.INFEASIBLE
const UNBOUNDED = JuMP.MathOptInterface.DUAL_INFEASIBLE



function createLspPlne(params, nodes, demands)

	model = Model(GLPK.Optimizer)

	#= Variables
		
	p_t  (Variable de production): quantité produite à la période t
	y_t  (Variable de lancement): variable binaire qui vaut 1 si une production est lancée à la période t, et 0 sinon

	I_it (Variable de stockage): quantité en stock à la fin de la période t pour i.
	
	q_it (Variable d’approvisionnement): quantité produite pour le revendeur i à la période t.

	=#

	#Variable Réel positive
	@variable(model, p[1:params["l"]] >= 0)


	@variable(model, I[0:params["n"], 1:params["l"]] >= 0)
	@variable(model, q[1:params["n"], 1:params["l"]] >= 0)



	#Variable binaire
	@variable(model, y[1:params["l"]], Bin)


	###Fonction objective
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
	###TODO: Contraintes
	




	#Affichage du programme linéaire
	println(model)

	return model

end


###Exemple
params, nodes, demands = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")

model = createLspPlne(params, nodes, demands)

###TODO: Creer la fonction de résolution
#reseolvePlne(model)
