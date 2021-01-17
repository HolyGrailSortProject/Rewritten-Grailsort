import setuptools
from Cython.Build import cythonize

setuptools.setup(
    name = 'GrailSort-Cython',
    version = '1.0',
    url = 'https://github.com/gaming32/GrailSort-Cython',
    author = 'Gaming32',
    author_email = 'gaming32i64@gmail.com',
    license = 'License :: OSI Approved :: MIT License',
    description = 'My Cython rewrite of GrailSort (see https://github.com/MusicTheorist/Rewritten-Grailsort)',
    ext_modules = cythonize('grailsort.pyx', language_level=3),
    zip_safe = False,
)
