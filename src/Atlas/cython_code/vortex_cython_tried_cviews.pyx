import numpy as np
cimport cython
cimport numpy as np 

from cython.view cimport array as cvarray

from openmdao.main.api import Component
from openmdao.lib.datatypes.api import Float, Array, Int
import numpy as np
from numpy import pi, cos, sin, mean, linspace, sqrt
#from numpy import pi, cos, sin, mean, linspace

#from libc.math cimport sin, cos, sqrt
from libc.math cimport sqrt as scalar_sqrt
from libc.math cimport cos as scalar_cos
from libc.math cimport sin as scalar_sin

DTYPE = np.double
ctypedef double DTYPE_t

@cython.boundscheck(False)
@cython.wraparound(False)
@cython.nonecheck(False)
@cython.cdivision(True)
def main_loop(
    double h,
    double rho,
    np.ndarray[DTYPE_t, ndim=2] yE,
    np.ndarray[DTYPE_t, ndim=2] dy,
    double[:] qh,
    int Nw,
    int Ntt,
    int Ns,
    np.ndarray[DTYPE_t, ndim=2] z,
    np.ndarray[DTYPE_t, ndim=2] r,
    np.ndarray[DTYPE_t, ndim=2]  Gamma,
    #double[:, ::1]  Gamma,
    double Omega,
    np.ndarray[DTYPE_t, ndim=2] dT, 
    np.ndarray[DTYPE_t, ndim=2] yN,
    double b,
    double dtheta,
    unsigned int Ntheta,
    double[:] thetaArray,
    double cr,
    np.ndarray[DTYPE_t, ndim=2] vi):
    '''
      converted original code into function so we could use Cython on all the variables and arrays
    '''

    cdef unsigned int t, tt, i, s, ii, ss, j
    cdef np.ndarray[DTYPE_t, ndim=2] vz_np = np.empty((Nw+1, Ns+1))
    cdef np.ndarray[DTYPE_t, ndim=2] vr_np = np.empty((Nw+1, Ns+1))
    #cdef double[:,::1] vz, vr
    cdef double zr, r_scalar, zp, yp, M, Z2
    cdef double acc1, acc2
    cdef double[:] Normal, X2, Y2, Norm3, sin_thetaArray, cos_thetaArray

    cdef double one_over_two_pi = 1.0/ ( 2.0 * pi )

    cdef double dt

    cdef double nl, n3, normal, inv_n3
    cdef double[:,::1] vz = cvarray(shape=(Nw+1, Ns+1), itemsize=sizeof(double), format="d")
    
    #cdef double[:,::1] vz = np.empty((Nw+1, Ns+1))
    cdef double[:,::1] vr = cvarray(shape=(Nw+1, Ns+1), itemsize=sizeof(double), format="d")

    #sin_thetaArray = np.empty(Ntheta)
    #cos_thetaArray = np.empty(Ntheta)
    sin_thetaArray = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")
    cos_thetaArray = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")
    for j in range(Ntheta):
        sin_thetaArray[j] = scalar_sin(thetaArray[j] )
        cos_thetaArray[j] = scalar_cos(thetaArray[j] )

    X2 = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")
    Y2 = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")
    Normal = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")
    Norm3 = cvarray(shape=(Ntheta,), itemsize=sizeof(double), format="d")

    dt = 2*pi / Omega / b / Ntt

    # cdef double[:,::1] vz = cvarray(shape=(Nw+1, Ns+1), itemsize=sizeof(double), format="d")
    
    #cdef double[:,::1] vz = np.empty((Nw+1, Ns+1))
    #cdef double[:,::1] vr = np.empty((Nw+1, Ns+1))
    #vz = np.empty((Nw+1, Ns+1))
    #vr = np.empty((Nw+1, Ns+1))

    # free-wake time stepping
    for t in range(Nw+1):
        # proceed with substeps
        for tt in range(Ntt):
            # Compute induced velocity on all ix(Ns+1) rings from all iix(Ns+1) rings
            #vz = np.zeros((Nw+1, Ns+1))
            #vr = np.zeros((Nw+1, Ns+1))
            for i in range(Nw+1):
                for j in range(Ns+1):
                    vz[i,j] = 0.0
                    vr[i,j] = 0.0
            for i in range(t):                       # for each disk
                for s in range(Ns+1):           # and for each ring on each disk
                    for ii in range(t):              # add the velocity induced from each disk
                        for ss in range(1, Ns+1):  # and each ring on each disk (inner ring cancels itself out)
                            zr = z[ii, ss]
                            r_scalar  = r[ii, ss]
                            zp = z[i, s]
                            yp = r[i, s]
                            M  = Gamma[ii, ss] * r_scalar * dtheta * one_over_two_pi
                            Z2 = (zp - zr)**2

                            #X2 = (-r_scalar*sin_thetaArray)**2
                            #Y2 = (yp - r_scalar*cos_thetaArray)**2
                            #Normal = sqrt(X2 + Y2 + Z2)
                            #vr[i, s] += np.sum(-cos_thetaArray * (zp - zr) / Norm3) * M
                            #vz[i, s] += np.sum((cos(thetaArray) * yp - r_scalar) / Norm3) * M
                            acc1 = acc2 = 0.0
                            for j in range(Ntheta):
                                X2[j] = (-r_scalar*sin_thetaArray[j])**2
                                Y2[j] = (yp - r_scalar*cos_thetaArray[j])**2
                                normal = scalar_sqrt(X2[j] + Y2[j] + Z2)
                                if normal < cr:
                                    normal = cr
                                inv_n3 = 1.0 / ( normal * normal * normal )
                                acc1 += -cos_thetaArray[j] * (zp - zr) * inv_n3
                                acc2 += (cos_thetaArray[j] * yp - r_scalar) * inv_n3
                            vr[i, s] += acc1 * M
                            vz[i, s] += acc2 * M

                            zr = -2*h - z[ii, ss]
                            Z2 = (zp - zr)**2

                            #Normal = sqrt(X2 + Y2 + Z2)
                            #vr[i, s] -= np.sum(-cos_thetaArray * (zp - zr) / Norm3) * M
                            #vz[i, s] -= np.sum((cos_thetaArray * yp - r_scalar) / Norm3) * M
                            acc1 = acc2 = 0.0
                            for j in range(Ntheta):
                                normal = scalar_sqrt(X2[j] + Y2[j] + Z2)
                                if normal < cr:
                                    normal = cr
                                inv_n3 = 1.0 / ( normal * normal * normal )
                                acc1 -= - cos_thetaArray[j] * (zp - zr) * inv_n3
                                acc2 -= (cos_thetaArray[j] * yp - r_scalar) * inv_n3
                            vr[i, s] += acc1 * M
                            vz[i, s] += acc2 * M

            # Compute altitude and time power approximation
            # if tt == 0:
            #     PiApprox = 8 * np.sum(dT.dot(vi))
            # realtime = 2*pi / Omega / b * ((t-1) * Ntt + tt) / Ntt
            # altitude = vc * realtime

            # Convect rings downstream
            for i in range(t):              # for each disk
                for s in range(Ns+1):  # and for each ring on each disk
                    z[i, s] = z[i, s] + vz[i, s]*dt
                    r[i, s] = r[i, s] + vr[i, s]*dt
                    Gamma[i, s] = Gamma[i, s]

        # Shift elements in ring array
        for i in range(t)[::-1]:
            Gamma[i+1, :] = Gamma[i, :]
            r[i+1, :] = r[i, :]
            z[i+1, :] = z[i, :]

        # Create nacent vortex rings
        GammaBound = dT / (rho*(Omega*yE)*dy)
        Gamma[0, 0] = -GammaBound[0]
        for s in range(1, Ns):
            Gamma[0, s] = GammaBound[s-1] - GammaBound[s]
        Gamma[0, Ns] = GammaBound[Ns-1]
        r[0, :] = yN.T
        z[0, :] = qh[:]

    # Compute induced velocity on rotor (rp = [0 r(s) 0])
    for s in range(Ns):                # for each element
        vi[s,0] = 0
        for ii in range(Nw):                # add the velocity induced from each disk
            for ss in range(1, Ns+1):  # and each ring on each disk (inner ring cancels itself out)
                if (ii == 0):
                    ringFrac = 0.675
                else:
                    ringFrac = 1

                zr = z[ii, ss]
                r_scalar  = r[ii, ss]
                zp = (qh[s] + qh[s+1]) / 2
                yp = yE[s,0]

                Z2 = (zp - zr)**2
                M  = Gamma[ii, ss] * r_scalar * dtheta * one_over_two_pi

                #vi[s] = vi[s] + ringFrac * np.sum((cos(self.thetaArray)*yp - r) / Norm3) * M
                acc1 = 0.0
                for j in range(Ntheta):
                    X2[j] = (-r_scalar*sin_thetaArray[j])**2
                    Y2[j] = (yp - r_scalar*cos_thetaArray[j])**2
                    normal = scalar_sqrt(X2[j] + Y2[j] + Z2)
                    if normal < cr:
                        normal = cr
                    inv_n3 = 1.0 / ( normal * normal * normal )
                    acc1 += (cos_thetaArray[j]*yp - r_scalar) * inv_n3
                vi[s,0] += ringFrac * acc1 * M

                # ground effect ring
                zr = -2*h - z[ii, ss]
                Z2 = (zp - zr)**2

                #vi[s] = vi[s] - ringFrac * np.sum((cos(self.thetaArray)*yp - r) / Norm3) * M
                acc2 = 0.0
                for j in range(Ntheta):
                    normal = scalar_sqrt(X2[j] + Y2[j] + Z2)
                    if normal < cr:
                        normal = cr
                    inv_n3 = 1.0 / ( normal * normal * normal )
                    acc2 += (cos_thetaArray[j]*yp - r_scalar) * inv_n3
                vi[s,0] -= ringFrac * acc2 * M

    #vz_np = np.asarray(<np.double_t[:, :]> vz)
    #vr_np = np.asarray(<np.double_t[:, :]> vr)
    for i in range(Nw+1):
        for j in range(Ns+1):
            vz_np[i,j] = vz[i,j]
            vr_np[i,j] = vr[i,j]
    return vz_np, vr_np, z, r, Gamma, vi

class VortexRingCython(Component):
    """
    Vortex ring calculations
    Computes the induced velocity on the rotor blades given the
    thrust distribution on the rotor
    """
    # inputs
    b        = Int(iotype='in', desc='number of blades')
    Ns       = Int(iotype='in', desc='number of elements')
    yN       = Array(iotype='in', desc='node locations')
    rho      = Float(iotype='in', desc='air density')
    vc       = Float(iotype='in', desc='vertical velocity')
    Omega    = Float(iotype='in', desc='rotor angular velocity')
    h        = Float(iotype='in', desc='height of rotor')
    dT       = Array(iotype='in', desc='thrust')
    q        = Array(iotype='in', desc='deformation')
    anhedral = Float(iotype='in')

    # outputs
    vi       = Array(iotype='out', desc='induced velocity')
    Gamma    = Array(iotype='out', desc='vortex strength')
    z        = Array(iotype='out', desc='')
    r        = Array(iotype='out', desc='')
    vz       = Array(iotype='out', desc='')
    vr       = Array(iotype='out', desc='')

    def execute(self):
        dy = np.zeros((self.Ns, 1))
        yE = np.zeros((self.Ns, 1))
        for s in range(self.Ns):
            dy[s] = self.yN[s+1] - self.yN[s]  # length of each element
            yE[s] = 0.5 * (self.yN[s] + self.yN[s+1])  # radial location of each element

        # set fidelity
        if self.Ns == 15:
            Nw = 15
            Ntt = 5
            Ntheta = 40
        elif self.Ns == 10:
            Nw = 8
            Ntt = 3
            Ntheta = 20
        else:
            Nw = 5
            Ntt = 1
            Ntheta = 15

        # Break out deformations
        qq = np.zeros((6, self.Ns+1))
        for s in range(1, self.Ns+1):
            qq[:, s] = self.q[s*6:s*6+6].T
        qh = (qq[2, :] - self.yN.T * self.anhedral).flatten()

        cr = 0.5 * mean(dy)
        dtheta = pi / Ntheta
        self.thetaArray = linspace(dtheta/2, pi - dtheta/2, Ntheta)

        # pre-allocate
        self.Gamma = np.zeros((Nw+1, self.Ns+1))
        self.z     = np.zeros((Nw+1, self.Ns+1))
        self.r     = np.zeros((Nw+1, self.Ns+1))
        self.vz    = np.zeros((Nw+1, self.Ns+1))
        self.vr    = np.zeros((Nw+1, self.Ns+1))
        self.vi    = np.zeros((self.Ns, 1))

        # create nacent vortex rings
        GammaBound = self.dT / (self.rho*(self.Omega*yE)*dy)

        self.Gamma[0, 0] = -GammaBound[0]
        for s in range(1, self.Ns):
            self.Gamma[0, s] = GammaBound[s-1] - GammaBound[s]
        self.Gamma[0, self.Ns] = GammaBound[self.Ns-1]

        self.r[0, :] = self.yN.T
        self.z[0, :] = qh[:]


        self.vz, self.vr, self.z, self.r, self.Gamma, self.vi = main_loop(
            self.h,
            self.rho,
            yE,
            dy,
            qh,
            Nw,
            Ntt,
            self.Ns,
            self.z,
            self.r,
            self.Gamma,
            self.Omega,
            self.dT,
            self.yN,
            self.b,
            dtheta,
            Ntheta,
            self.thetaArray,
            cr,
            self.vi)

        # vi is positive downwards
        self.vi = -self.vi

