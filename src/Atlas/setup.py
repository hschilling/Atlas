# from distutils.core import setup
# from Cython.Build import cythonize

# setup(
#     ext_modules = cythonize("vortex_cython.pyx")
# )

from setuptools import setup, Extension
from Cython.Distutils import build_ext
import numpy as np

NAME = "vortex_cython"
VERSION = "0.1"
DESCR = "Speed up vortex code using cython"
URL = "http://openmdao.org"
REQUIRES = ['numpy', 'cython']

AUTHOR = "Herb Schilling"
EMAIL = "herbschilling@gmail.com"

LICENSE = "Apache 2.0"

SRC_DIR = "cython_code"
PACKAGES = [SRC_DIR]

ext_1 = Extension(SRC_DIR + ".vortex_cython",
                  [SRC_DIR + "/vortex_cython.pyx",],
                  libraries=[],
                  include_dirs=[np.get_include()])


EXTENSIONS = [ext_1]

if __name__ == "__main__":
    setup(install_requires=REQUIRES,
          packages=PACKAGES,
          zip_safe=False,
          name=NAME,
          version=VERSION,
          description=DESCR,
          author=AUTHOR,
          author_email=EMAIL,
          url=URL,
          license=LICENSE,
          cmdclass={"build_ext": build_ext},
          ext_modules=EXTENSIONS
          )
