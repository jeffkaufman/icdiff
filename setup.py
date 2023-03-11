from distutils.util import convert_path
from setuptools import setup, find_packages
from icdiff import __version__

setup(
    name="icdiff",
    version=__version__,
    url="https://www.jefftk.com/icdiff",
    project_urls={
        "Source": "https://github.com/jeffkaufman/icdiff",
    },
    classifiers=[
        "License :: OSI Approved :: Python Software Foundation License"
    ],
    author="Jeff Kaufman",
    author_email="jeff@jefftk.com",
    description="improved colored diff",
    long_description=open('README.md').read(),
    scripts=['git-icdiff'],
    py_modules=['icdiff'],
    entry_points={
        'console_scripts': [
            'icdiff=icdiff:start',
        ],
    },
)
