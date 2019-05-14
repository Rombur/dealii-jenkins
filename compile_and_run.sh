#!/bin/bash
cd /home
# This should be taken care of by Jenkins but there is a strange bug when we
# let Jenkins clone the repo
git clone https://github.com/dealii/dealii
cd /home && mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/home/install -DDEAL_II_WITH_CUDA=ON \
  -DDEAL_II_WITH_CXX14=OFF  \
  -DDEAL_II_WITH_CXX17=OFF  \
  -DDEAL_II_WITH_MPI=ON \
  -DDEAL_II_WITH_P4EST=ON \
  -DDEAL_II_WITH_TRILINOS=ON \
  ../dealii
ctest -DTRACK="Continuous" -DMAKEOPTS="-j12" -j12 -V -S ../dealii/tests/run_testsuite.cmake
# Because we clone the repo ourselves and didn't build deal.II at the right
# place, we need to move the build directory ourselves so that Jenkins can parse
# the output files.
cd /home
rm -r $1/build
mv build $1
