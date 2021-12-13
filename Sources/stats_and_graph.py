import matplotlib.pyplot as plt
import numpy as np
import os

def VRP_String_ToCircuit(dict_exec, n=14, isPDI=False, t=1):
    circuits = []

    endString = "]"

    if isPDI:
        endString = f",{t}]"

    for i in range(1,n+1):
		#On cherche tout les chemin commençant en 0 (Début de circuit)
        key=f'x[0,{i}' + endString
        if round(dict_exec[key]) > 0:

            circuit = [0]
			#from deviant le premier noeud après 0 du circuit
            fromNode = i

            #Puis tant qu'on a pas fais une boucle (Un circuit complet)...
            k=0
            while fromNode != 0 :
                #On ajout fromNode ici pour ne pas avoir de 0 à la fin
                circuit.append(fromNode)

                for i in range(n+1):
                    if i != fromNode:
                        #...On cherche le noeud suivant fromNode...
                        key=f'x[{fromNode},{i}' + endString
                        if round(dict_exec[key]) > 0:
                            #...Et ce noeud devient fromNode
                            fromNode = i
                            break
                    if(i==n):
                        fromNode=0
            circuits.append(circuit)
    return circuits

def stringJuliaDict_toPythonDict(stringJuliaDict:str):
    pythonDict={}

    stringJuliaDict=stringJuliaDict.split("(")[1]
    stringJuliaDict=stringJuliaDict.split(")")[0]
    elems=stringJuliaDict.split(", ")
    for elem in elems:
        key=elem.split(" => ")[0].split("\"")[1]
        value=float(elem.split(" => ")[1])
        pythonDict[key]=value
    return pythonDict

def getAllPDI_Size14(typeExact=True,typeHeuristic_Heuristic=False,type_Heuristic_VRP=False):
    """retourne toutes les benchmarks sous forme de dictionnaire résumant l'execution de PDI Exact/Heuristique ou Heuristique avec VRP de taille 14
    les clés-valeurs sont :

    solver_name : str
    termination_status : str
    primal_status : str
    dual_status : str
    raw_status : str
    result_count : int
    has_values : bool
    has_duals : bool
    objective_value : float
    objective_bound : float
    dual_objective_value : float
    Solutions : Dict avec comme clés les variables de décision de PDI et comme valeur leur valeur après résolution
    Constraints : str
    solve_time : float
    simplex_iterations : int
    barrier_iterations : int
    node_count : int

    Returns
    -------
    [type]
        [description]
    """
    if typeExact:
        typeOfExec="Branch&Cut_A_014"
    elif typeHeuristic_Heuristic:
        typeOfExec="Branch&Cut_Heuristic_"
    elif type_Heuristic_VRP:
        typeOfExec="Branch&Cut_Heuristic_withVRP"
    allDir=os.walk("./sources/evaluations")
    allResumesPath=[]
    count=0
    for (dir_path,_,elems) in allDir:
        count+=1
        if(count>2):
            mySplit=dir_path.split("/")[-1].split("_")
            typeOfBenchmark=mySplit[0]+"_"+mySplit[1]+"_"+mySplit[2]
            if typeOfBenchmark==typeOfExec:
                for elem in elems:
                    typeOfFile=elem.split("_")[0]
                    if typeOfFile=="resume":
                        allResumesPath.append(dir_path+"/"+elem)
    
    allData=[]
    for resumePath in allResumesPath:
        with open(resumePath,'r') as resume:
            data={}
            while True:
                readLine1=resume.readline()
                readLine2=resume.readline()
                if not readLine1 or not readLine2:
                    break
                line_name=readLine1.split(" ")[0].split()[0]
                if line_name!="Solutions":
                    line_object=readLine2.split()[0]
                else:
                    line_object=readLine2
                data[line_name]=line_object
                resume.readline()
                

        data["result_count"]=int(data["result_count"])
        data["has_values"]=bool(data["has_values"])
        data["has_duals"]=bool(data["has_duals"])
        data["objective_value"]=float(data["objective_value"])
        data["objective_bound"]=float(data["objective_bound"])
        data["dual_objective_value"]=float(data["dual_objective_value"])
        data["Solutions"]=stringJuliaDict_toPythonDict(data["Solutions"])

        data["solve_time"]=float(data["solve_time"])        
        data["simplex_iterations"]=int(data["simplex_iterations"])
        data["barrier_iterations"]=int(data["result_count"])
        data["node_count"]=int(data["node_count"])

        allData.append(data)
    return allData

def getAllVRP_exact_and_heuristic(size=14):
    allDir=os.walk("./sources/evaluations")
    allCircuitPathClarkWrigth=[]
    allCircuitPathVRP=[]
    allModelPath=[]
    count=0
    for (dir_path,_,elems) in allDir:
        count+=1
        if(count>2):
            mySplit=dir_path.split("/")[-1].split("_")
            typeOfBenchmark=mySplit[0]+"_"+mySplit[1]+"_"+mySplit[2]
            if typeOfBenchmark=="VRPHeuristic_and_ExactA" and int(mySplit[3])==size:
                for elem in elems:
                    typeOfFile=elem.split("_")
                    if(typeOfFile[0]=="all"):
                        allModelPath.append(dir_path+"/"+elem)
                    elif(typeOfFile[2]=="clarkWrightA"):
                        allCircuitPathClarkWrigth.append(dir_path+"/"+elem)
                    elif(typeOfFile[2]=="VRPA"):
                        allCircuitPathVRP.append(dir_path+"/"+elem)

    allCircuitClarkWrigth=[]
    allTimeClarkWrigth=[]
    for path in allCircuitPathClarkWrigth:
        with open(path,'r') as circuitPath_clark:
            count=0
            while True:
                count+=1
                line=circuitPath_clark.readline()
                if count>1:
                    if not line :
                        break
                    circuit_temp=[]
                    for node in line.split("\t")[-1].split("[")[-1].split("]")[0].split(", "):
                        circuit_temp.append(int(node))
                    allTimeClarkWrigth.append(float(line.split("\t")[-2].split()[0])/1000)
                    allCircuitClarkWrigth.append(circuit_temp)

    allCircuitVRP=[]
    allTimeVRP=[]
    for path in allCircuitPathVRP:
        with open(path,'r') as circuitPath_VRP:
            count=0
            while True:
                count+=1
                line=circuitPath_VRP.readline()
                if count>1:
                    if not line :
                        break
                    circuit_temp=[]
                    for node in line.split("\t")[-1].split("[")[-1].split("]")[0].split(", "):
                        circuit_temp.append(int(node))
                    allTimeVRP.append(float(line.split("\t")[-2].strip()))
                    allCircuitVRP.append(circuit_temp)

    allModels=[]
    for path in allModelPath:
        with open(path,'r') as modelFile:
            while True:
                line=modelFile.readline()
                if not line :
                    break
                if line[0]=="#":
                    data={}
                    while True:
                        line_name=modelFile.readline().split(" ")[0]
                        line_object=modelFile.readline()
                        modelFile.readline()
                        data[line_name]=line_object
                        if not line_object or not line_name or line_name=="node_count":
                            break
                    data["result_count"]=int(data["result_count"])
                    data["has_values"]=bool(data["has_values"])
                    data["has_duals"]=bool(data["has_duals"])
                    data["objective_value"]=float(data["objective_value"])
                    data["objective_bound"]=float(data["objective_bound"])
                    data["dual_objective_value"]=float(data["dual_objective_value"])
                    data["Solutions"]=stringJuliaDict_toPythonDict(data["Solutions"])

                    data["solve_time"]=float(data["solve_time"])        
                    data["simplex_iterations"]=int(data["simplex_iterations"])
                    data["barrier_iterations"]=int(data["result_count"])
                    data["node_count"]=int(data["node_count"])
                    allModels.append(data)
    return allCircuitClarkWrigth,allCircuitVRP,allModels,allTimeClarkWrigth,allTimeVRP

def getStatsPDI():
    dataExact=getAllPDI_Size14(True,False,False)
    dataHeuristique=getAllPDI_Size14(False,True,False)
    dataVRP=getAllPDI_Size14(False,False,True)

    tempsExact=[data["solve_time"] for data in dataExact]
    tempsHeuristique=[data["solve_time"] for data in dataHeuristique]
    tempsVRP=[data["solve_time"] for data in dataVRP]

    objective_valueExact=[data["objective_value"] for data in dataExact]
    objective_valueHeuristique=[data["objective_value"] for data in dataHeuristique]
    objective_valueVRP=[data["objective_value"] for data in dataVRP]

    isOptimal_Exact=[data["termination_status"]=="OPTIMAL" for data in dataExact]
    isOptimal_Heuristique=[data["termination_status"]=="OPTIMAL" for data in dataHeuristique]
    isOptimal_VRP=[data["termination_status"]=="OPTIMAL" for data in dataVRP]
    # Exact
    # Heuristique
    # VRP

    #mean
    moyenneTempsExecExact=np.mean(tempsExact)
    moyenneTempsExecHeuristic=np.mean(tempsHeuristique)
    moyenneTempsExecVRP=np.mean(tempsVRP)
    moyenne_objective_valueExact=np.mean(objective_valueExact)
    moyenne_objective_valueHeuristique=np.mean(objective_valueHeuristique)
    moyenne_objective_valueVRP=np.mean(objective_valueVRP)

    #ecart type
    EcartTypeTempsExecExact=np.std(tempsExact)
    EcartTypeTempsExecHeuristic=np.std(tempsHeuristique)
    EcartTypeTempsExecVRP=np.std(tempsVRP)
    EcartType_objective_valueExact=np.std(objective_valueExact)
    EcartType_objective_valueHeuristique=np.std(objective_valueHeuristique)
    EcartType_objective_valueVRP=np.std(objective_valueVRP)

    #nbOptimal
    nbOptimalExact=np.sum(isOptimal_Exact)/len(isOptimal_Exact)
    nbOptimalHeuristique=np.sum(isOptimal_Heuristique)/len(isOptimal_Heuristique)
    nbOptimalVRP=np.sum(isOptimal_VRP)/len(isOptimal_VRP)

    #circuits
    allCircuits_Exact=[] #liste des circuits, pour tous les benchmarks, pour tous les pas de temps
    allCircuits_Heuristique=[]
    allCircuits_VRP=[]
   

    for data in dataExact:
        circuitsTempst=[]
        for t in range(1,7):
            circuitsTempst.append(VRP_String_ToCircuit(data["Solutions"], 6, True, t))
        allCircuits_Exact.append(circuitsTempst)
    # for data in dataHeuristique:
    #     circuitsTempst=[]
    #     for t in range(1,7):
    #         circuitsTempst.append(VRP_String_ToCircuit(data["Solutions"], 6, True, t))
    #     allCircuits_Heuristique.append(circuitsTempst)
    # for data in dataVRP:
    #     circuitsTempst=[]
    #     for t in range(1,7):
    #         circuitsTempst.append(VRP_String_ToCircuit(data["Solutions"], 6, True, t))
    #     allCircuits_VRP.append(circuitsTempst)
    
    #moyenne de longueur circuit par pas de temps
    moyenneLongueurPasDeTemps={} #t=>longueur moyenne des circuits sur le pas de temps t
    moyenneNbCircuitPasDeTemps={} #t=>Nombre moyen des circuits sur le pas de temps t
    denominateur={}
    for t in range(0,7):
        moyenneLongueurPasDeTemps[t]=0
        moyenneNbCircuitPasDeTemps[t]=0
        denominateur[t]=1
    for execution_i in allCircuits_Exact:
        for all_circuits_temps_t in execution_i:
            for (t,circuit_temps_t) in enumerate(all_circuits_temps_t):
                moyenneLongueurPasDeTemps[t]+=len(circuit_temps_t)
                moyenneNbCircuitPasDeTemps[t]+=1
            if t in moyenneLongueurPasDeTemps.keys():
                denominateur[t]+=len(all_circuits_temps_t)
    for (t,moyenne) in moyenneLongueurPasDeTemps.items():
        moyenneLongueurPasDeTemps[t]=moyenne/denominateur[t]
    for (t,moyenne) in moyenneNbCircuitPasDeTemps.items():
        moyenneNbCircuitPasDeTemps[t]/=len(allCircuits_Exact)

    return ("moyenneTempsExecExact",moyenneTempsExecExact),("moyenneTempsExecHeuristic",moyenneTempsExecHeuristic),("moyenneTempsExecVRP",moyenneTempsExecVRP),("moyenne_objective_valueExact",moyenne_objective_valueExact),("moyenne_objective_valueHeuristique",moyenne_objective_valueHeuristique),("moyenne_objective_valueVRP",moyenne_objective_valueVRP), ("EcartTypeTempsExecExact",EcartTypeTempsExecExact),("EcartTypeTempsExecHeuristic",EcartTypeTempsExecHeuristic),("EcartTypeTempsExecVRP",EcartTypeTempsExecVRP),("EcartType_objective_valueExact",EcartType_objective_valueExact),("EcartType_objective_valueHeuristique",EcartType_objective_valueHeuristique),("EcartType_objective_valueVRP",EcartType_objective_valueVRP),("nbOptimalExact",nbOptimalExact),("nbOptimalHeuristique",nbOptimalHeuristique),("nbOptimalVRP",nbOptimalVRP),("allCircuits_Exact",allCircuits_Exact),("moyenneLongueurPasDeTemps",moyenneLongueurPasDeTemps),("moyenneNbCircuitPasDeTemps",moyenneNbCircuitPasDeTemps)#,allCircuits_VRP,allCircuits_Heuristique

def getStatsVRP(size=14):
    allCircuitClarkWrigth,allCircuitVRP,allModels,allTimeClarkWrigth,allTimeVRP=getAllVRP_exact_and_heuristic(size)

    mean_circuit_size_ClarkWrigth=np.mean([len(circuit) for circuit in allCircuitClarkWrigth])
    mean_circuit_size_VRP=np.mean([len(circuit) for circuit in allCircuitVRP])
    std_circuit_size_ClarkWrigth=np.std([len(circuit) for circuit in allCircuitClarkWrigth])
    std_circuit_size_VRP=np.std([len(circuit) for circuit in allCircuitVRP])

    mean_timeClarkWrigth=np.mean(allTimeClarkWrigth)
    mean_timeVRP=np.mean(allTimeVRP)
    stdClarkWrigth=np.std(allTimeClarkWrigth)
    stdVRP=np.std(allTimeVRP)

    return ("mean_circuit_size_ClarkWrigth",mean_circuit_size_ClarkWrigth),("mean_circuit_size_VRP",mean_circuit_size_VRP),("std_circuit_size_ClarkWrigth",std_circuit_size_ClarkWrigth),("std_circuit_size_VRP",std_circuit_size_VRP),("mean_timeClarkWrigth",mean_timeClarkWrigth),("mean_timeVRP",mean_timeVRP),("stdClarkWrigth",stdClarkWrigth),("stdVRP",stdVRP)

#print(getStatsPDI())
print(getStatsVRP(size=14))

