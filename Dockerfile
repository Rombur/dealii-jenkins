FROM nvidia/cuda:10.1-devel
#FROM nvidia/cuda:9.0-devel
#FROM nvidia/cuda:8.0-devel

# ssh is needed by openmpi
RUN apt update && apt upgrade -y && apt install -y \
    build-essential \
    gfortran \ 
    wget \
    zlib1g-dev \
    python-dev \
    lbzip2 \
    liblapack-dev \
    ssh \
    git \
    numdiff \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV N_PROCS=1                                                 


ENV PREFIX=/scratch
ENV ARCHIVE_DIR=${PREFIX}/archive
ENV SOURCE_DIR=${PREFIX}/source
ENV BUILD_DIR=${PREFIX}/build                                                 
ENV INSTALL_DIR=/opt                                                 

RUN mkdir -p ${PREFIX} && \
    cd ${PREFIX} && \
    mkdir archive && \
    mkdir source && \
    mkdir build

# Install CMake
RUN export CMAKE_VERSION=3.14.3 && \
    export CMAKE_VERSION_SHORT=3.14 && \
    export CMAKE_URL=https://cmake.org/files/v${CMAKE_VERSION_SHORT}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz && \
    export CMAKE_ARCHIVE=${ARCHIVE_DIR}/cmake.tar.gz && \
    export CMAKE_BUILD_DIR=${BUILD_DIR}/cmake && \
    wget --quiet ${CMAKE_URL} --output-document=${CMAKE_ARCHIVE}  && \
    mkdir -p ${CMAKE_BUILD_DIR} && \
    tar xf ${CMAKE_ARCHIVE} -C ${CMAKE_BUILD_DIR} --strip-components=1 && \
    mv ${CMAKE_BUILD_DIR} ${INSTALL_DIR} && \
    rm -rf ${CMAKE_ARCHIVE} && \
    rm -rf ${CMAKE_BUILD_DIR}
ENV PATH=${INSTALL_DIR}/cmake/bin:$PATH

# Install OpenMPI
RUN export OPENMPI_VERSION=4.0.1 && \
    export OPENMPI_VERSION_SHORT=4.0 && \
    export OPENMPI_SHA1=35bf7c9162b08ecdc4876af573786cd290015631 && \
    export OPENMPI_URL=https://www.open-mpi.org/software/ompi/v${OPENMPI_VERSION_SHORT}/downloads/openmpi-${OPENMPI_VERSION}.tar.bz2 && \
    export OPENMPI_ARCHIVE=${ARCHIVE_DIR}/openmpi-${OPENMPI_VERSION}.tar.bz2 && \
    export OPENMPI_SOURCE_DIR=${SOURCE_DIR}/openmpi && \
    export OPENMPI_BUILD_DIR=${BUILD_DIR}/openmpi && \
    export OPENMPI_INSTALL_DIR=${INSTALL_DIR}/openmpi && \
    wget --quiet ${OPENMPI_URL} --output-document=${OPENMPI_ARCHIVE} && \
    echo "${OPENMPI_SHA1} ${OPENMPI_ARCHIVE}" | sha1sum -c && \
    mkdir -p ${OPENMPI_SOURCE_DIR} && \
    tar -xf ${OPENMPI_ARCHIVE} -C ${OPENMPI_SOURCE_DIR} --strip-components=1 && \
    mkdir -p ${OPENMPI_BUILD_DIR} && \
    cd ${OPENMPI_BUILD_DIR} && \
    ${OPENMPI_SOURCE_DIR}/configure --prefix=${OPENMPI_INSTALL_DIR} && \
    make -j${N_PROCS} install && \
    rm -rf ${OPENMPI_ARCHIVE} && \
    rm -rf ${OPENMPI_BUILD_DIR} && \
    rm -rf ${OPENMPI_SOURCE_DIR}
# Put OPENMPI_DIR at the end of the path so that /usr/local/bin/mpiexec will
# overwrite it
ENV PATH=$PATH:${INSTALL_DIR}/openmpi/bin

# Install Boost
RUN export BOOST_VERSION=1.67.0 && \
    export BOOST_VERSION_U=1_67_0 && \
    export BOOST_URL=https://dl.bintray.com/boostorg/release/${BOOST_VERSION}/source/boost_${BOOST_VERSION_U}.tar.bz2 && \
    export BOOST_SHA256=2684c972994ee57fc5632e03bf044746f6eb45d4920c343937a465fd67a5adba && \
    export BOOST_ARCHIVE=${ARCHIVE_DIR}/boost_${BOOST_VERSION_U}.tar.bz2 && \
    export BOOST_SOURCE_DIR=${SOURCE_DIR}/boost && \
    export BOOST_BUILD_DIR=${BUILD_DIR}/boost && \
    export BOOST_INSTALL_DIR=${INSTALL_DIR}/boost && \
    wget --quiet ${BOOST_URL} --output-document=${BOOST_ARCHIVE} && \
    echo "${BOOST_SHA256} ${BOOST_ARCHIVE}" | sha256sum -c && \
    mkdir -p ${BOOST_SOURCE_DIR} && \
    tar -xf ${BOOST_ARCHIVE} -C ${BOOST_SOURCE_DIR} --strip-components=1 && \
    cd ${BOOST_SOURCE_DIR} && \
    ./bootstrap.sh \
        --prefix=${BOOST_INSTALL_DIR} \
        && \
    echo "using mpi ;" >> project-config.jam && \
    ./b2 -j${N_PROCS}\
        --build-dir=${BOOST_BUILD_DIR} \
        hardcode-dll-paths=true dll-path=${BOOST_INSTALL_DIR}/lib \
        link=shared \
        variant=release \
        install \
        && \
    rm -rf ${BOOST_ARCHIVE} && \
    rm -rf ${BOOST_BUILD_DIR} && \
    rm -rf ${BOOST_SOURCE_DIR}
ENV BOOST_ROOT=${INSTALL_DIR}/boost

# Install Trilinos
RUN export TRILINOS_VERSION=12-14-1 && \
    export TRILINOS_URL=https://github.com/trilinos/Trilinos/archive/trilinos-release-${TRILINOS_VERSION}.tar.gz && \
    export TRILINOS_ARCHIVE=${ARCHIVE_DIR}/trilinos.tar.gz && \
    export TRILINOS_SOURCE_DIR=${SOURCE_DIR}/trilinos && \
    export TRILINOS_BUILD_DIR=${BUILD_DIR}/trilinos && \
    export TRILINOS_INSTALL_DIR=${INSTALL_DIR}/trilinos && \
    wget --quiet ${TRILINOS_URL} --output-document=${TRILINOS_ARCHIVE} && \
    mkdir -p ${TRILINOS_SOURCE_DIR} && \
    tar -xf ${TRILINOS_ARCHIVE} -C ${TRILINOS_SOURCE_DIR} --strip-components=1 && \
    mkdir ${TRILINOS_BUILD_DIR} && \
    cd ${TRILINOS_BUILD_DIR} && \
    cmake -DCMAKE_BUILD_TYPE=RELEASE -DBUILD_SHARED_LIBS=ON \
        -DTPL_ENABLE_MPI=ON \
        -DTPL_ENABLE_BLAS=ON \
        -DTPL_ENABLE_LAPACK=ON \
        -DTPL_ENABLE_Boost=ON \
        -DBoost_INCLUDE_DIRS=${BOOST_ROOT}/include \
        -DTPL_ENABLE_BoostLib=ON \
        -DBoostLib_INCLUDE_DIRS=${BOOST_ROOT}/include \
        -DBoostLib_LIBRARY_DIRS=${BOOST_ROOT}/lib \
        -DTrilinos_ENABLE_ALL_PACKAGES=OFF \
        -DTrilinos_ENABLE_ALL_OPTIONAL_PACKAGES=OFF \
        -DTrilinos_ENABLE_TESTS=OFF \
        -DTrilinos_ENABLE_EXAMPLES=OFF \
        -DTrilinos_ENABLE_Amesos=ON \
        -DTrilinos_ENABLE_AztecOO=ON \
        -DTrilinos_ENABLE_Epetra=ON \
        -DTrilinos_ENABLE_EpetraExt=ON \
        -DTrilinos_ENABLE_Ifpack=ON \
        -DTrilinos_ENABLE_ML=ON \
        -DTrilinos_ENABLE_MueLu=ON \
        -DTrilinos_ENABLE_EXPLICIT_INSTANTIATION=ON \
        -DCMAKE_INSTALL_PREFIX=${TRILINOS_INSTALL_DIR} \
        ${TRILINOS_SOURCE_DIR} && \
    make -j${N_PROCS} install && \
    rm -rf ${TRILINOS_ARCHIVE} && \
    rm -rf ${TRILINOS_BUILD_DIR} && \
    rm -rf ${TRILINOS_SOURCE_DIR}
ENV TRILINOS_DIR=${INSTALL_DIR}/trilinos

# Install p4est
RUN export P4EST_VERSION=2.2 && \
    export P4EST_URL=http://p4est.github.io/release/p4est-${P4EST_VERSION}.tar.gz && \
    export P4EST_ARCHIVE=${ARCHIVE_DIR}/p4est-${P4EST_VERSION}.tar.gz && \
    export P4EST_SOURCE_DIR=${SOURCE_DIR}/p4est && \
    export P4EST_BUILD_DIR=${BUILD_DIR}/p4est && \
    export P4EST_INSTALL_DIR=${INSTALL_DIR}/p4est && \
    wget --quiet ${P4EST_URL} --output-document=${P4EST_ARCHIVE} && \
    mkdir -p ${P4EST_SOURCE_DIR} && \
    cd ${P4EST_SOURCE_DIR} && \
    wget --quiet https://www.dealii.org/8.5.0/external-libs/p4est-setup.sh && \
    bash ./p4est-setup.sh ${P4EST_ARCHIVE} ${P4EST_INSTALL_DIR} && \
    rm -rf ${P4EST_ARCHIVE} && \
    rm -rf ${P4EST_BUILD_DIR} && \
    rm -rf ${P4EST_SOURCE_DIR}
ENV P4EST_DIR=${INSTALL_DIR}/p4est

# Append the option flag --allow-run-as-root to mpiexec
RUN echo '#!/usr/bin/env bash' > /usr/local/bin/mpiexec && \
    echo '${INSTALL_DIR}/openmpi/bin/mpiexec --allow-run-as-root "$@"' >> /usr/local/bin/mpiexec && \
    chmod +x /usr/local/bin/mpiexec

COPY compile_and_run.sh /home/compile_and_run.sh
