#!/bin/bash
cd /home
# This should be taken care of by Jenkins but there is a strange bug when we
# let Jenkins clone the repo
git clone https://github.com/dealii/dealii
mkdir build && cd build
cmake -DCMAKE_INSTALL_PREFIX=/home/install -DDEAL_II_WITH_CUDA=ON -DDEAL_II_WITH_CXX14=OFF ../dealii
# This should not be done but if we don't do it there is a warning on a 
# line with the word error in it. When ctest check that the build was 
# correct, it greps the word error, thinks that the build failed and
# stops right away.
make -j12 
ctest -DMAKEOPTS="-j12" -j12 -V -S ../dealii/tests/run_testsuite.cmake
# Because we clone the repo ourselves and didn't build deal.II at the right
# place, we need to move the build directory ourselves so that Jenkins can parse
# the output files.
cd /home
rm -r $1/build
mv build $1
