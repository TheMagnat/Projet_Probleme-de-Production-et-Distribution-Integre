

function getAllInstancesPath(directory="./PRP_instances")
    return readdir(directory,join=true)
end

function getAllInstancesPathFromType(type="A")
    if type!="A" && type!="B"
        println("Choisir un type entre A et B")
        return []
    else
        paths=getAllInstancesPath()
        return filter(e->first(split(last(split(e,"/")),"_"))==type,paths) #instances_paths
    end
end

function getAllInstancesPathFromTypeAndSize(type="A",size=15)
    allSizes=[15,50,100,200]
    if !in(size,allSizes)
        print("Pas d'instance de taille $size")
        return []
    else
        instances_path_rightType=getAllInstancesPathFromType(type)
        
        return filter(e->parse(Int,split(last(split(e,"/")),"_")[2])==size,instances_path_rightType) #instances_path_rightType_rightSize
    end
end


#= TODO : 
1 - Comparer en terme de vitesse et en fitness sur des instances de tailles différentes: 
    - la résolution de VRP avec
        - la formulation MTZ 
        - les différentes métaheuristiques
2 - Analyser les performances du LSP en terme de vitesse et en fitness sur des instances de tailles différentes
3 - Comparer en terme de vitesse et en fitness sur des instances de tailles différentes:
    -  PDI avec la résolution
        - heuristique
        -  exacte
Donc à chaque fois : 
- enregistrer le temps d'execution, la fitness, les solutions
- Répéter les executions sur toutes les instances de tailles de différentes (arreter si trop long)
- sauvegarder les résultats sur un .txt afin de pouvoir les plotter en python
=#