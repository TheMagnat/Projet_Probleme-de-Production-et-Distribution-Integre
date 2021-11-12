#Fichier qui permet de créer les différents PLNE pour le problème du VRP

using JuMP
using CPLEX
#using GLPK

include("InstanceLoader.jl")

function createVRP_MTZ(params, nodes, demands, costs, t)

    model = Model(CPLEX.Optimizer)
    #model = Model(GLPK.Optimizer)

    #=

    m = nb de véhicule
    Q = capacité d'un véhicule

    =#
    
    m = params["k"]
    n = params["n"]
    Q = params["Q"]


    ####################VARIABLES#######################
    @variable(model, x[i=0:n, j=0:n], Bin)#Variable binaire x_(i,j) pour chaque arête
    for i in 0:n
        delete(model, x[i, i]) #on enlève les variables qui correspondent aux arêtes en trop (les (i, i))
    end

    @variable(model, 0 <= w[i=1:n] <= Q)#Variables w_i
    

    ####################CONTRAINTES####################
    @constraint(model, sum(x[0, j] for j in 1:n) <= m)#contrainte 6
    @constraint(model, sum(x[i, 0] for i in 1:n) <= m)#contrainte 7


    for i in 0:n

        nodesIndexWithoutI = filter(e -> e != i, 0:n)

        @constraint(model, sum(x[i,j] for j in nodesIndexWithoutI) == 1)#contraintes 8
        @constraint(model, sum(x[j,i] for j in nodesIndexWithoutI) == 1)#contraintes 9

    end


    for i in 1:n

        nodesIndexWithoutI = filter(e -> e != i, 1:n)
        for j in nodesIndexWithoutI
            @constraint(model, w[i] - w[j] >= demands[i, t] - (Q+demands[i, t]) * (1 - x[i, j]))#contrainte 10
        end

    end

    ####################FONCTION OBJECTIF####################
    @objective(model, Min, sum(edgeCost * x[edge[1], edge[2]] for (edge, edgeCost) in costs))

    return model

end

#Exemple
#params, nodes, demands, costs = readPRP("../PRP_instances/A_014_#ABS1_15_1.prp")

#model = createVRP_MTZ(params, nodes, demands, costs, 1)

#println(model)
