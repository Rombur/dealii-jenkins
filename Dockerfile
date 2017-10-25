#FROM nvidia/cuda:9.0-devel
FROM nvidia/cuda:8.0-devel

# ssh is needed by openmpi
RUN apt update && apt upgrade -y && apt install -y \
    build-essential \
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

# We need cmake 3.9 or later for CUDA
RUN cd /home && \
    wget https://cmake.org/files/v3.9/cmake-3.9.1-Linux-x86_64.tar.gz && \
    tar xf cmake-3.9.1-Linux-x86_64.tar.gz && \
    mv ./cmake-3.9.1-Linux-x86_64 /opt && \
    rm -r /home/*

ENV PATH=/opt/cmake-3.9.1-Linux-x86_64/bin:$PATH

# We need boost 1.65.1 or later for CUDA 9.0
RUN cd /home && \
    wget https://dl.bintray.com/boostorg/release/1.65.1/source/boost_1_65_1.tar.gz && \
    tar xf boost_1_65_1.tar.gz && cd boost_1_65_1 && \
    ./bootstrap.sh --prefix=/opt/boost && ./b2 install \
    rm -r /home/*

ENV BOOST_ROOT=/opt/boost

COPY compile_and_run.sh /home/compile_and_run.sh
