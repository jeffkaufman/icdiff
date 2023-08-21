from setuptools import setup
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
    long_description_content_type='text/markdown',
    scripts=['git-icdiff'],
    py_modules=['icdiff'],
    entry_points={
        'console_scripts': [
            'icdiff=icdiff:start',
        ],
    },
)
