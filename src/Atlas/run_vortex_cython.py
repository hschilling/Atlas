import os
import numpy as np

from scipy.io import loadmat

from Atlas import VortexRingCython
#from vortex_cython import VortexRing

@profile
def f():
        comp = VortexRingCython()

        # populate inputs
        path = os.path.join(os.path.dirname(__file__), 'test/vortex.mat')
        data = loadmat(path, struct_as_record=True, mat_dtype=True)

        comp.b        = int(data['b'][0][0])
        comp.yN       = data['yN']
        comp.Ns       = max(comp.yN.shape) - 1

        comp.rho      = data['rho'][0][0]
        comp.vc       = data['vc'][0][0]
        comp.Omega    = data['Omega'][0][0]
        comp.h        = data['h'][0][0]
        comp.dT       = data['dT']
        comp.q        = data['q']
        comp.anhedral = data['anhedral'][0][0]

        comp.run()

f()
