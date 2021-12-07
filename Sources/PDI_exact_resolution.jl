using JuMP
using CPLEX
using Combinatorics

include("LSP_PLNE.jl")
include("InstanceLoader.jl")
include("ResolvePlne.jl")
include("Helper.jl")
include("VRP_PLNE.jl")

function createPDI_Bard_Nananukul_compacte(params, nodes, demands, costs)
    model = Model(CPLEX.Optimizer)
    n = params["n"] #nombre de revendeur (exclu le fournisseur donc)
    m = params["k"] #nb de véhicules
    l=params["l"] #nombre de pas de temps
    Q = params["Q"] #capacité d'un vahicule
    C=params["C"] #production max du fournisseur à un certain pas de temps
    u=params["u"] #coût de production d'une unité
    f=params["f"] #coût de setup

    M=Dict(t=>min(C,sum(sum( demands[i,j] for i in 1:n) for j in t:l)) for t in 1:l )
    M_tilde=Dict((i,t)=> min( nodes[i]["L"], Q, sum(demands[i,j] for j in t:l) ) for i in 1:n,t in 1:l)

    @variable(model,p[t=1:l]>=0) #(13)
    @variable(model, I[0:n, 0:l] >= 0) #(13)
    @variable(model, q[1:n, 1:l] >= 0) #(13)
    @variable(model, y[1:l], Bin) #(14)
    @variable(model, x[i=0:n, j=0:n,t=1:l], Bin) #(14)
    for i in 0:n, t in 1:l
        delete(model, x[i, i, t]) #on enlève les variables qui correspondent aux arêtes en trop (les (i, i))
    end
    @variable(model, z[i=1:n, t=1:l], Bin) #(15)
    @variable(model, 0 <= z0[ 0 , t=1:l ] <= m, Int) #(16) et (10) #ATTENTION IL Y A DEUX z À GERER: z0=z QUAND i=0 CAR JuMP NE NOUS LAISSE PAS INSTANCIER EN DEUX FOIS UNE VARIABLE, OR C'EST NECESSAIRE CAR LES z0 SONT DES ENTIERS POSITIFS ET LES z SONT DES NOMBRE BINAIRES
    @variable(model,0<=w[i=1:n,t=1:l]) #(12 partie 1)

    for t in 1:l
        @constraint(model, I[0, t-1] + p[t] == I[0, t] + sum(q[i, t] for i in 1:n)) #(2)
        @constraint(model, p[t] <= M[t] * y[t]) #(4)
        @constraint(model, I[0, t] <= nodes[0]["L"]) #(5)
        @constraint(model,sum(x[j,0,t]+x[0,j,t] for j in 1:n)==2*z0[0,t]) #(9 que pour i=0)

        for i in 1:n
			@constraint(model, I[i, t-1] + q[i, t] == demands[i, t] + I[i, t]) #(3)
			@constraint(model, I[i, t-1] + q[i, t] <= nodes[i]["L"]) #(6)
            @constraint(model,q[i,t]<=M_tilde[i,t]*z[i,t]) #(7) la qté à livrer ne peut être positive que si on visite le noeud à ce pas de temps et ne doit pas dépasser la capacité d'un seul véhicule (un noeud n'est servi que par un seul véhicule) 

            nodesIndexWithoutI = filter(e -> e != i, 0:n)
            @constraint(model, sum(x[i,j,t] for j in nodesIndexWithoutI)==z[i,t]) #(8)
            @constraint(model,sum(x[j,i,t]+x[i,j,t] for j in nodesIndexWithoutI)==2*z[i,t]) #(9 avec i in 1:n)

            @constraint(model,w[i , t] <= Q*z[i,t]) # (12 partie 2)
		end

        for ((i,j),edgeCost) in costs
            if(i!=0 && j!=0)
                @constraint(model,w[i,t]-w[j,t]>=q[i,t]-M_tilde[i,t]*(1-x[i,j,t])) #(11)
            end
        end
    end

    @objective(model,Min,sum(u*p[t]+f*y[t]+sum(nodes[i]["h"]*I[i,t] for i in 0:n)+sum(edgeCost*x[i,j,t] for ((i,j),edgeCost) in costs) for t in 1:l)) #(1)

    return model

end

#=
Formulation non compacte, la contrainte (29) contient 2^n inégalités
=#
function createPDI_Boudia(params, nodes, demands, costs)
    model = Model(CPLEX.Optimizer)
    n = params["n"] #nombre de revendeur (exclu le fournisseur donc)
    m = params["k"] #nb de véhicules
    l=params["l"] #nombre de pas de temps
    Q = params["Q"] #capacité d'un vahicule
    C=params["C"] #production max du fournisseur à un certain pas de temps
    u=params["u"] #coût de production d'une unité
    f=params["f"] #coût de setup
    a=1

    M=Dict(t=>min(C,sum(sum( demands[i,j] for i in 1:n) for j in t:l)) for t in 1:l )
    M_tilde=Dict((i,t)=> min( nodes[i]["L"], Q, sum(demands[i,j] for j in t:l) ) for i in 1:n,t in 1:l)

    
    @variable(model,p[t=1:l]>=0) #(31)
    @variable(model, I[0:n, 0:l] >= 0) #(31)
    @variable(model, q[1:n, k=1:m, 1:l] >= 0) #(31)
    @variable(model, y[1:l], Bin) #(32)
    @variable(model, x[i=0:n, j=0:n, k=1:m, t=1:l], Bin) #(32)
    for i in 0:n, t in 1:l, k=1:m
        delete(model, x[i, i, k, t]) #on enlève les variables qui correspondent aux arêtes en trop (les (i, i))
    end
    @variable(model, z[i=0:n, k=1:m, t=1:l], Bin) #(32)
    
    for t in 1:l
        @constraint(model, I[0,t-1]+p[t] == sum(sum(q[i,k,t]+I[0,t] for k in 1:m) for i in 1:n)) #(21)
        @constraint(model,p[t]<=M[t]*y[t]) #(23)
        @constraint(model, I[0,t]<=nodes[0]["L"]) #(24)
        for i in 1:n
            @constraint(model,I[i,t-1]+sum(q[i,k,t] for k in 1:m)==demands[i,t]+I[i,t]) #(22)
            #@constraint(model, I[i,t-1]+sum(q[k,i,t] for k in 1:m)<=nodes[i]["L"]) #(25) #erreur sur le PDF ? 
            @constraint(model, I[i,t-1]+sum(q[i,k,t] for k in 1:m)<=nodes[i]["L"]) #(25) 
            @constraint(model,sum(z[i,k,t] for k in 1:m)<=1) #(27)
            for k in 1:m
                @constraint(model,q[i,k,t]<=M_tilde[i,t]*z[i,k,t]) #(26)
                nodesIndexWithoutI = filter(e -> e != i, 0:n)
                @constraint(model,sum(x[j,i,k,t] for j in nodesIndexWithoutI)+sum(x[i,j,k,t] for j in nodesIndexWithoutI)==2*z[i,k,t]) #(28 pour i>=1)
            end
        end

    
        for k in 1:m
            @constraint(model,sum(x[j,0,k,t] for j in 0:n)+sum(x[0,j,k,t] for j in 1:n)==2*z[0,k,t]) #(28 pour i=0)
            @constraint(model,sum(q[i,k,t] for i in 1:n)<=Q*z[0,k,t]) #(30)
    
            for S in powerset(1:n, 2, n)
                @constraint(model,sum(sum(x[i,j,k,t] for j in S) for i in S)<=length(S)-1) #(29)
            end
        end

    end
    @objective(model,Min,sum(u*p[t]+f*y[t]+sum(nodes[i]["h"]*I[i,t] for i in 0:n)+sum(edgeCost*sum(x[i,j,k,t] for k in 1:m) for ((i,j),edgeCost) in costs) for t in 1:l)) #(20)

    return model

end
