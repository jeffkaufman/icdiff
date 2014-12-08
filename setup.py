import setuptools

setuptools.setup(
    name="icdiff",
    version="1.1.0",
    url="http://www.jefftk.com/icdiff",
    author="Jeff Kaufman",
    author_email="jeff@jefftk.com",
    description="improved colored diff",
    long_description=open('README').read(),
    scripts=['icdiff', 'git-icdiff'],
)
