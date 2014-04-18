import numpy as np

cimport numpy as np
from libc.math cimport sqrt
cimport cython


def f() :
    cdef np.ndarray[ np.double_t, ndim=2] some_array
    some_array = np.zeros( (50,50), dtype = np.double )
