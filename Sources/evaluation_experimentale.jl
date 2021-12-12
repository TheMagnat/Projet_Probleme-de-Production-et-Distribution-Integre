using StatsBase
include("VRP_Heuristic.jl")
include("PDI_heuristic_resolution.jl")
include("BranchAndCut.jl")

function getAllInstancesPath(directory = "./PRP_instances")
    return readdir(directory, join = true)
end

function getAllInstancesPathFromType(type = "A")
    if type != "A" && type != "B"
        println("Choisir un type entre A et B")
        return []
    else
        paths = getAllInstancesPath()
        return filter(e -> first(split(last(split(e, "/")), "_")) == type, paths) #instances_paths
    end
end

function getAllInstancesPathFromTypeAndSize(type = "A", size = 14)
    allSizes = [14, 50, 100, 200]
    if !in(size, allSizes)
        print("Pas d'instance de taille $size")
        return []
    else
        instances_path_rightType = getAllInstancesPathFromType(type)

        return filter(e -> parse(Int, split(last(split(e, "/")), "_")[2]) == size, instances_path_rightType) #instances_path_rightType_rightSize
    end
end
function _try_get(f, model)
    try
        return f(model)
    catch
        return missing
    end
end
function _get_solution_dict(model)
    dict = Dict{String,Float64}()
    if has_values(model)
        for x in all_variables(model)
            variable_name = name(x)
            if !isempty(variable_name)
                dict[variable_name] = value(x)
            end
        end
    end
    return dict
end
function _get_constraint_dict(model)
    dict = Dict{String,Float64}()
    if has_duals(model)
        for (F, S) in list_of_constraint_types(model)
            for constraint in all_constraints(model, F, S)
                constraint_name = name(constraint)
                if !isempty(constraint_name)
                    dict[constraint_name] = dual(constraint)
                end
            end
        end
    end
    return dict
end
function getSelectedInstances(nbA14 = 20, nbA50 = 3, nbA100 = 0, nbB50 = 3, nbB100 = 0, nbB200 = 0)
    A14 = getAllInstancesPathFromTypeAndSize("A", 14)
    A50 = getAllInstancesPathFromTypeAndSize("A", 50)
    A100 = getAllInstancesPathFromTypeAndSize("A", 100)
    B50 = getAllInstancesPathFromTypeAndSize("B", 50)
    B100 = getAllInstancesPathFromTypeAndSize("B", 100)
    B200 = getAllInstancesPathFromTypeAndSize("B", 200)
    return [sample(A14, nbA14), sample(A50, nbA50), sample(A100, nbA100), sample(B50, nbB50), sample(B100, nbB100), sample(B200, nbB200)]
end

function callBranchAndCut(instances)
    for instance in instances
        #get the instance
        params, nodes, demands, costs = readPRP(instance)

        #Optimize
        model = BranchAndCutPDI(params, nodes, demands, costs)

        #create the directory
        timestamp = Dates.format(now(), "YYYYmmdd-HHMMSS")
        name = first(split(last(split(instance, "/")), "."))
        dir_name = joinpath(@__DIR__,"evaluations","Branch&Cut_$(name)_" * "$timestamp")
        @assert !ispath(dir_name) "Somebody else already created the directory"
        mkpath(dir_name)

        #save the circuits
        allCircuits = PDItoCircuits(model, params, nodes, demands, costs)
        saveMultiCircuits(params, allCircuits, dir_name * "/all_circuits.png")

        #save the model
        #write_to_file(model, dir_name * "/model_$(name).mps")
        towrite=["solver_name",solver_name(model),"\ntermination_status :",
        termination_status(model),"\nprimal_status :",
        primal_status(model),"\ndual_status :",
        dual_status(model),"\nraw_status :",
        raw_status(model),"\nresult_count :",
        result_count(model),"\nhas_values :",
        has_values(model),"\nhas_duals :",
        has_duals(model),"\nobjective_value :",
        _try_get(objective_value, model),"\nobjective_bound :",
        _try_get(objective_bound, model),"\ndual_objective_value :",
        _try_get(dual_objective_value, model),"\nSolutions :",
        _get_solution_dict(model),"\nConstraints :",
        _get_constraint_dict(model),"\nsolve_time :",
        _try_get(solve_time, model),"\nsimplex_iterations :",
        _try_get(simplex_iterations, model),"\nbarrier_iterations :",
        _try_get(barrier_iterations, model),"\nnode_count :",
        _try_get(node_count, model)]
        s=""
        for w in towrite
            s=s*string(w)*"\n"
        end
        file = open(dir_name *"/resume_exec_$(name).txt", "w")
	    write(file, s)
	    close(file) 
    end
end

function callVRPHeuristic_and_Exact(instances)
    for instance in instances
        #get the instance
        params, nodes, demands, costs = readPRP(instance)

        #create the directory
        timestamp = Dates.format(now(), "YYYYmmdd-HHMMSS")
        name = first(split(last(split(instance, "/")), "."))
        dir_name = joinpath(@__DIR__,"evaluations","VRPHeuristic_and_Exact$(name)_" * "$timestamp")
        @assert !ispath(dir_name) "Somebody else already created the directory"
        mkpath(dir_name)

        #open the files
        file_heuristique = open(dir_name *"/circuits_de_clarkWright$(name).txt", "w")
        file_VRP = open(dir_name *"/circuits_de_VRP$(name).txt", "w")
        file_model=open(dir_name *"/all_models_de_VRP$(name).txt", "w")
	    write(file_heuristique, "t\trealisable\ttime\tcircuit\n")
        write(file_VRP, "t\trealisable\ttime\tcircuit\n")

        #get the circuits from metaheuristic and VRP for all time steps and save the model for all time steps
        for t in 1:params["l"]
            #save the heuristic's circuit
            start=now()
            circuits_temps_t_heuristique = mixMetaheuristic(clark_wright(params, nodes, demands, costs,t),params,costs)
            elapsed=now()-start
            isRealisable=true
            for circuit in circuits_temps_t_heuristique
                isRealisable=isRealisable&&length(circuit)<=params["k"]
                if !isRealisable
                    break
                end
            end
            write(file_heuristique, "$t\t$isRealisable\t$elapsed\t$(circuits_temps_t_heuristique)\n")

            #save the VRP's circuits
            model = createVRP_MTZ(params, nodes, demands, costs, t)
            optimize!(model)
            circuits_temps_t_VRP =vrpToCircuit(model, params, false, t)
            isRealisabl_VRPe=length(circuits_temps_t_VRP)<=params["k"]
            write(file_VRP, "$t\t$isRealisabl_VRPe\t$(_try_get(solve_time, model))\t$(circuits_temps_t_VRP)\n")
            
            #save the model
            towrite=["solver_name",solver_name(model),"\ntermination_status :",
            termination_status(model),"\nprimal_status :",
            primal_status(model),"\ndual_status :",
            dual_status(model),"\nraw_status :",
            raw_status(model),"\nresult_count :",
            result_count(model),"\nhas_values :",
            has_values(model),"\nhas_duals :",
            has_duals(model),"\nobjective_value :",
            _try_get(objective_value, model),"\nobjective_bound :",
            _try_get(objective_bound, model),"\ndual_objective_value :",
            _try_get(dual_objective_value, model),"\nSolutions :",
            _get_solution_dict(model),"\nConstraints :",
            _get_constraint_dict(model),"\nsolve_time :",
            _try_get(solve_time, model),"\nsimplex_iterations :",
            _try_get(simplex_iterations, model),"\nbarrier_iterations :",
            _try_get(barrier_iterations, model),"\nnode_count :",
            _try_get(node_count, model)]
            s="\n#$t\n"
            for w in towrite
                s=s*string(w)*"\n"
            end
            write(file_model,s)
        end
        
	    close(file_heuristique)
        close(file_VRP)
        close(file_model)

    end
end

function callPDIHeuristic(instances,nbMaxIte, resoudreVRPwithHeuristic)
    for instance in instances
        for instance in instances
            #get the instance
            lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial=initialisation_PDI_heuristique(instance)
    
            #Optimize
            model,circuits=PDI_heuristique(lsp_model, params, nodes, demands, costs, SC, fonctionObjInitial, nbMaxIte, resoudreVRPwithHeuristic)
    
            #create the directory
            timestamp = Dates.format(now(), "YYYYmmdd-HHMMSS")
            name = first(split(last(split(instance, "/")), "."))
            withVRP=resoudreVRPwithHeuristic ? "" : "withVRP"
            dir_name = joinpath(@__DIR__,"evaluations","Branch&Cut_Heuristic_$(withVRP)_$(name)_" * "$timestamp")
            @assert !ispath(dir_name) "Somebody else already created the directory"
            mkpath(dir_name)
    
            #save the circuits
            circuits_list=[[] for i in 1:length(circuits)]
            for (i,circuit) in circuits
                circuits_list[i]=circuit
            end
            saveMultiCircuits(params, circuits_list, dir_name * "/all_circuits.png")
    
            #save the model
            #write_to_file(model, dir_name * "/model_$(name).mps")
            towrite=["solver_name",solver_name(model),"\ntermination_status :",
            termination_status(model),"\nprimal_status :",
            primal_status(model),"\ndual_status :",
            dual_status(model),"\nraw_status :",
            raw_status(model),"\nresult_count :",
            result_count(model),"\nhas_values :",
            has_values(model),"\nhas_duals :",
            has_duals(model),"\nobjective_value :",
            _try_get(objective_value, model),"\nobjective_bound :",
            _try_get(objective_bound, model),"\ndual_objective_value :",
            _try_get(dual_objective_value, model),"\nSolutions :",
            _get_solution_dict(model),"\nConstraints :",
            _get_constraint_dict(model),"\nsolve_time :",
            _try_get(solve_time, model),"\nsimplex_iterations :",
            _try_get(simplex_iterations, model),"\nbarrier_iterations :",
            _try_get(barrier_iterations, model),"\nnode_count :",
            _try_get(node_count, model)]
            s=""
            for w in towrite
                s=s*string(w)*"\n"
            end
            file = open(dir_name *"/resume_exec_$(name).txt", "w")
            write(file, s)
            close(file) 
        end
    end
end

function evaluatePDI_BranchAndCut(nbA14 = 30, nbA50 = 30, nbA100 = 10, nbB50 = 0, nbB100 = 0, nbB200 = 0) #time limit de 3h pour chaque instance
    allInstances = getSelectedInstances(nbA14, nbA50, nbA100, nbB50, nbB100, nbB200)
    for instances in allInstances
        if length(instances)!=0
            callBranchAndCut(instances)
        end
    end
end

function evaluateVRP_Heuristique_and_Exact(nbA14 = 0, nbA50 = 1, nbA100 = 0, nbB50 = 0, nbB100 = 0, nbB200 = 0)
    allInstances = getSelectedInstances(nbA14, nbA50, nbA100, nbB50, nbB100, nbB200)
    for instances in allInstances
        callVRPHeuristic_and_Exact(instances)
    end
end


function evaluatePDI_heuristique(nbA14 = 10, nbA50 = 5, nbA100 = 2, nbB50 = 0, nbB100 = 0, nbB200 = 0, nbMaxIte=100, resoudreVRPwithHeuristic=false)
    allInstances = getSelectedInstances(nbA14, nbA50, nbA100, nbB50, nbB100, nbB200)
    for instances in allInstances
        callPDIHeuristic(instances,nbMaxIte, resoudreVRPwithHeuristic)
    end
end



#evaluatePDI_BranchAndCut(20,0,0,0,0,0)
evaluateVRP_Heuristique_and_Exact()
#evaluatePDI_heuristique()


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