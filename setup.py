from distutils.util import convert_path
import setuptools

package_data = {}
exec(open("icdiff").read(), package_data)

setuptools.setup(
    name="icdiff",
    version=package_data.get('__version__'),
    url="http://www.jefftk.com/icdiff",
    author="Jeff Kaufman",
    author_email="jeff@jefftk.com",
    description="improved colored diff",
    long_description=open('README.md').read(),
    scripts=['icdiff', 'git-icdiff'],
)
