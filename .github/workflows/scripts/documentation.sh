#!/bin/bash
set -e
set -o pipefail

python3 -m venv pyenv && . pyenv/bin/activate
pip3 install --upgrade pip
 
# cython is required because git does not contain _NetworKit.
pip3 install 'cython==0.29.*'

# Several modules are required to build the documentation.
# Note: First, install an old version of sphinx to be compatible with all addons. 
# Try to raise this version when possible.
pip3 install 'sphinx<5' 
pip3 install 'Jinja2<3.1.0' sphinx_bootstrap_theme 'numpydoc<1.6.0' exhale nbsphinx breathe
pip3 install sphinx_copybutton sphinxcontrib.bibtex sphinx_gallery sphinx_last_updated_by_git 
pip3 install ipykernel ipython matplotlib nbconvert jupyter-client networkx tabulate
pip3 install ipycytoscape plotly seaborn powerlaw

# Build the C++ core library (no need for optimizations).
mkdir core_build && cd "$_"
cmake -DCMAKE_BUILD_TYPE=Debug -DNETWORKIT_CXX_STANDARD=$CXX_STANDARD -DNETWORKIT_WARNINGS=ON ..
make -j2
cd ..

# Build the Python extension.
export CMAKE_LIBRARY_PATH=${CMAKE_LIBRARY_PATH:+$CMAKE_LIBRARY_PATH:}$(pwd)/core_build
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH:+$LD_LIBRARY_PATH:}$(pwd)/core_build
export CPU_COUNT=$(python3 $GITHUB_WORKSPACE/.github/workflows/scripts/get_core_count.py)
NETWORKIT_PARALLEL_JOBS=$CPU_COUNT python3 ./setup.py build_ext --inplace --networkit-external-core
NETWORKIT_PARALLEL_JOBS=$CPU_COUNT pip3 install -e .

# Build the documentation.
cd core_build
make docs
touch htmldocs/.nojekyll
rm -rf htmldocs/{.buildinfo,.doctrees}
