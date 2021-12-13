
import pandas as pd
import numpy as np


def readMetaCSV():
	data = pd.read_csv("../Sources/metaheuristic.csv")

	nToArr = {}

	for index, row in data.iterrows():

		name = row.iloc[0]

		n = int(name[2:5])

		if n not in nToArr:
			nToArr[n] = []

		rez = [0] * 6

		for j, elem in enumerate(row.iloc[1:]):
	 		rez[j] = elem

		nToArr[n].append(rez)


	for (key, value) in nToArr.items():

		values = np.array(value)

		print(key)
		print( np.round( values.mean(axis=0) ) )

		#zeroVersion = values[:, 0:3] - values[:, 0:3].min(axis=1).reshape(-1, 1)
		zeroVersion = values - values.min(axis=1).reshape(-1, 1)
		unique, counts = np.unique(np.argwhere(zeroVersion == 0)[:, 1], return_counts=True)
		occur = dict(zip(unique, np.round(counts/values.shape[0], 3)))
		print(occur)


def readMTZCSV():
	data = pd.read_csv("../Sources/mtz_meta.csv")

	nToArr = {}

	for index, row in data.iterrows():

		name = row.iloc[0]

		n = int(name[2:5])

		if n not in nToArr:
			nToArr[n] = []

		rez = [0] * 4

		for j, elem in enumerate(row.iloc[1:]):
	 		rez[j] = elem

		nToArr[n].append(rez)


	for (key, value) in nToArr.items():

		values = np.array(value)

		print(key)
		print( np.round( values.mean(axis=0), 5 ) )
		print( np.round( values.max(axis=0), 5 ) )
		print( np.round( values.std(axis=0), 5 ) )
		print (((values[:, 2] - values[:, 0])).argmax())

		#zeroVersion = values[:, 0:3] - values[:, 0:3].min(axis=1).reshape(-1, 1)
		#zeroVersion = values - values.min(axis=1).reshape(-1, 1)
		#unique, counts = np.unique(np.argwhere(zeroVersion == 0)[:, 1], return_counts=True)
		#occur = dict(zip(unique, np.round(counts/values.shape[0], 3)))
		#print(occur)

#readMTZCSV()
readMetaCSV()


