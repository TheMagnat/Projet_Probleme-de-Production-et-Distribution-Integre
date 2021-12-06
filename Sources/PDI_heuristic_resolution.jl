using JuMP
using CPLEX
include("LSP_PLNE.jl")
include("InstanceLoader.jl")
include("ResolvePlne.jl")
include("Helper.jl")
include("VRP_Heuristic.jl")
include("VRP_PLNE.jl")

#=
Initialise la résolution heuristique du PDI :
 --> créer le modèle (PLNE) LSP
 --> y ajoute les SC dans la fonction objectif
 --> y ajoute les nouvelles variables de décision z_i,t binaire
 --> créer les contraintes liant les z_i,t et q_i,t
=#
function initialisation_PDI_heuristique(INSTANCE_PATH)
        #Récuperer l'instance
    params, nodes, demands, costs = readPRP(INSTANCE_PATH)
        #Créer le PLNE LSP associé à l'instance
    lsp_model = createLSP(params, nodes, demands, costs)
        #Creer les SC
    SC=Array{Int,2}(undef,params["n"],params["l"])
        #Prendre la fonction objectif
    fonctionObj=objective_function(lsp_model)
    fonctionObjInitial=objective_function(lsp_model)

    #####Initialisation des variables binaires z_i,t#####
    @variable(lsp_model,z[1:params["n"], 1:params["l"]],Bin)


    for revendeur in 1:params["n"]
        for pasDeTemps in 1:params["l"]
    ######Couplage entre q_i,t et z_i,t#####
            #si z=1, on peut produire pour le revendeur autant que params["C] 
            #qui est la capacité de production du fournisseur, sinon on ne produit pas
            @constraint(lsp_model,variable_by_name(lsp_model, "q[$revendeur,$pasDeTemps]")<=z[revendeur,pasDeTemps]*params["C"])
            #si on ne produit pas alors z est forcément nul.
            @constraint(lsp_model,z[revendeur,pasDeTemps]<=variable_by_name(lsp_model, "q[$revendeur,$pasDeTemps]"))

            #initialiser les SC_i,t
            SC[revendeur,pasDeTemps]=costs[0,revendeur]+costs[revendeur,0]

            #Changer la fonction objectif pour ajouter les coûts de visite
            fonctionObj+=SC[revendeur,pasDeTemps]*z[revendeur,pasDeTemps]
        end
    end

    #mettre la nouvelle fonction objectif
    set_objective_function(lsp_model,fonctionObj)

    return lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial
end

#= 
    Crée un modèle (PLNE) de VRP 
=#
function getVRPfromLSP(lsp_model,params, nodes, demands, costs)
    qteALivrer = Array{Float64, 2}(undef, params["n"], params["l"]) #qteALivrer[i,t] = qté à livrer au revendeur i au pas de temps t
	notEmptyIndexAtT = [[] for i in 1:params["l"]] #Pour stocker les revendeurs qui ont été livré au pas de temps t
    
	for i in 1:params["n"]
		for t in 1:params["l"]
			qteALivrer[i, t] = value(variable_by_name(lsp_model, "q[$i,$t]")) #stocker les qté à livrer pour tous les revendeurs, pour tous les pas de temps
			if qteALivrer[i, t] != 0 #si on doit livrer quelque chose i au pas de temps t, on l'ajoute dans la liste
				push!(notEmptyIndexAtT[t], i)
			end

		end
	end

	tToVrp = Any[]
	for t in 1:params["l"]
		#On copie les paramètres mais n prend la valeur du nombre de noeud avec une demande supérieur à 0
		copyParams = copy(params)
		copyParams["n"] = size(notEmptyIndexAtT[t], 1)


		#On copie les informations des noeuds mais dans sans les noeud avec une demande 0
		copyNodes = Array{Dict, 1}(undef, size(notEmptyIndexAtT[t], 1) + 1) # copyNodes[i]= le ième noeud ayant une qté à livrer non nulle

		#On copie les demande à chaque temps mais sans les noeud avec une demande à 0
		copyQteALivrer = Array{Float64, 2}(undef, size(notEmptyIndexAtT[t], 1), params["l"]) #copyQteALivrer[i,t] = la qté à livrer du ième noeud ayant une qté à livrer non nulle

		#Initialise le noeud 0 à part
		copyNodes[1] = nodes[0]
		
		for i in eachindex(notEmptyIndexAtT[t])
			copyNodes[i+1] = nodes[notEmptyIndexAtT[t][i]]# copyNodes[i]= le ième noeud ayant une qté à livrer non nulle
			copyQteALivrer[i, :] = qteALivrer[notEmptyIndexAtT[t][i], :]#copyQteALivrer[i,t] = la qté à livrer du ième noeud ayant une qté à livrer non nulle
		end

		#On remet les index en commençant à 0
		copyNodes = OffsetVector(copyNodes, 0:(size(copyNodes, 1) - 1))

		#Un dictionnaire faisant le lien entre les anciens index et les nouveaux (Dû au décalage d'index dans les array)
		isPresent = Dict{Int, Int}()

		for (index, elem) in enumerate(notEmptyIndexAtT[t])
			isPresent[elem] = index
		end

		isPresent[0] = 0

		#On copie les coûts de transports mais sans les arêtes passant par un noeud avec une demande à 0
		copyCost = Dict{Tuple{Int, Int}, Float64}()
		for (edge, edgeCost) in costs

			if in(edge[1], keys(isPresent)) && in(edge[2], keys(isPresent)) #si les deux noeuds formant une arête sont présent dans la liste des noeuds ayant une qté à livrer non nulle
				copyCost[(isPresent[edge[1]], isPresent[edge[2]])] = edgeCost
			end

		end

		push!(tToVrp, (copyParams, copyNodes, copyQteALivrer, copyCost))
        #=
        On fait un VRP avec un nombre de noeuds n réduit (< au n initial) où:
        On ne garde que les noeuds dont on doit livrer à un certain pas de temps, on a gardé dans le dictionnaire des noeuds l'index d'origine pour mieux se retrouver
        On ne garde que les qté à livrer non nulle pour chaque pas de temps
        on ne garde que les arcs et les coûts de ces arcs que s'ils ne sont reliés à deux noeuds auxquels on doit livrer (sous graphe induit par les noeuds qu'on doit livrer)        
        =#

	end

    #On renvoi les modèles de VRP à résoudre
    vrp_models_et_parametres_en_fonction_du_pasDeTemps=Dict(t => (createVRP_MTZ(tToVrp[t][1],tToVrp[t][2],tToVrp[t][3],tToVrp[t][4],t),tToVrp[t]) for t in 1:params["l"])
	return vrp_models_et_parametres_en_fonction_du_pasDeTemps

end

function getSCfromVRPCircuits(vrp_circuits, SC, pasDeTemps, params, costs)
    revendeur_visites=Dict{Int,Tuple}() #nodeID => (predecesseur, successeur)=(i-,i+)
    for circuit in vrp_circuits #on trouve tous les noeuds visités ainsi que ses successeur et predecesseur dans son circuit
        for (index,revendeur) in enumerate(circuit)
            if index==1 #le revendeur est 0 (c'est le fournisseur), rappel : on a toujour circuit[1]=0
                revendeur_visites[revendeur]=(circuit[length(circuit)],circuit[index+1])
            elseif index==length(circuit)
                revendeur_visites[revendeur]=(circuit[index-1],circuit[1])
            else
                revendeur_visites[revendeur]=(circuit[index-1],circuit[index+1])
            end
        end
    end
    for (revendeur,(predecesseur, successeur)) in revendeur_visites #on met à jour les SC pour les visités
        SC[revendeur,pasDeTemps]=costs[predecesseur,revendeur]+costs[revendeur,successeur]-costs[predecesseur,successeur]
    end
    for nodeToInsert in 1:params["n"] #on met à jour les SC pour les non visités
        if !(nodeToInsert in keys(revendeur_visites))#si le revendeur n'est pas visité
            #coût si on inserait nodeToInsert après revendeur
            coutInsertion=[cost[revendeur,nodeToInsert]+cost[nodeToInsert,successeur]-cost[revendeur,successeur] for (revendeur,(predecesseur, successeur)) in revendeur_visites]
            #SC[nodeToInsert,pasDeTemps]=min([coutInsertion]) #marche pas ... chelou
            min=coutInsertion[1]
            for cout in coutInsertion
                min=min<cout ? min : cout
            end
            SC[nodeToInsert,pasDeTemps]=min
        end
    end
    return SC
end

function update_LSP(lsp_model,SC,fonctionObjInitial)
    fonctionObj=fonctionObjInitial
    for revendeur in 1:params["n"]
        for pasDeTemps in 1:params["l"]
            fonctionObj+=SC[revendeur,pasDeTemps]*variable_by_name(lsp_model, "z[$revendeur,$pasDeTemps]")
        end
    end

    #mettre la nouvelle fonction objectif
    set_objective_function(lsp_model,fonctionObj)

end

function PDI_heuristique(lsp_model, params, nodes, demands, costs, SC , fonctionObjInitial, nbMaxIte=10, resoudreVRPwithHeuristic=true)
    for _ in 1:nbMaxIte
        #résolution LSP
        println("============================================================================SOLVING============================================================================")
        println("============================================================================SOLVING============================================================================")
        println("============================================================================SOLVING============================================================================")
        println("============================================================================SOLVING============================================================================\n\n\n")
        lsp_model=resolvePlne(lsp_model,2,"")

        if(!resoudreVRPwithHeuristic)
            #récuperer les VRP pour chaque pas de temps
            vrp_models_et_parametres_en_fonction_du_pasDeTemps=getVRPfromLSP(lsp_model,params, nodes, demands, costs)
        end
        #résolution VRP à chaque pas de temps
        allCircuits=[]
        for pasDeTemps in 1:params["l"]

            #résoudre VRP
            if(resoudreVRPwithHeuristic) #si on fait avec l'heuristique clark wright
                vrp_circuits=clark_wright(params, nodes, demands, costs, pasDeTemps)
            else #si on fait une résolution exacte
                #récuperer le VRP pour le pas de temps correspondant ainsi les params, nodes, demands, costs de ce VRP
                vrp_model,(copyParams, copyNodes, copyQteALivrer, copyCost)=vrp_models_et_parametres_en_fonction_du_pasDeTemps[pasDeTemps]
                #retrouver les indexOriginaux
                originalIndexes=Dict(i-1 => e["initial_index"] for (i,e) in enumerate(copyNodes))
                #résolution exacte de VRP
                vrp_model=resolvePlne(vrp_model,0,"")
                #prendre les circuits à partir du modèle de VRP, ils sont décrit avec les index locaux
                vrp_circuits_temp=vrpToCircuit(vrp_model, copyParams)
                #revenir aux index initiaux
                vrp_circuits=[]
                for circuit in vrp_circuits_temp
                    circuit_with_Original_index=[originalIndexes[k] for k in circuit]
                    push!(vrp_circuits,circuit_with_Original_index)
                end
            end
            #prendre les SC_i,pasDeTemps depuis les circuits calculé dans le VRP
            if(empty!(vrp_circuits)==false)
                SC=getSCfromVRPCircuits(vrp_circuits, SC, pasDeTemps, params, costs)
            end
        end
        
        #mettre à jour les SC dans le modèle du LSP
        update_LSP(lsp_model,SC,fonctionObjInitial)
        
    end
    return lsp_model
end


INSTANCE_PATH = "/Users/davidpinaud/GitHub/Projet_Probleme-de-Production-et-Distribution-Integre/PRP_instances/A_014_ABS83_15_4.prp"
lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial=initialisation_PDI_heuristique(INSTANCE_PATH)
lsp_model=PDI_heuristique(lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial, 10, false)