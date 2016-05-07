import glob
from setuptools import setup, find_packages
from icdiff import __version__

setup(
    name="icdiff",
    version=__version__,
    url="http://www.jefftk.com/icdiff",
    author="Jeff Kaufman",
    author_email="jeff@jefftk.com",
    description="improved colored diff",
    long_description=open('README.md').read(),
    scripts=glob.glob('scripts/*'),
    py_modules=['icdiff'],
    license='Python',
    packages = find_packages(),
)
