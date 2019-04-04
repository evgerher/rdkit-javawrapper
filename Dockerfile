FROM debian:buster AS rdkit-build-env

RUN apt-get update \
 && apt-get install -yq --no-install-recommends \
 		libpcre3-dev \
 		software-properties-common \
    ca-certificates \
    build-essential \
    cmake \
    libboost-dev \
    libboost-system-dev \
    libboost-thread-dev \
    libboost-serialization-dev \
    libboost-python-dev \
    libboost-regex-dev \
    libcairo2-dev \
    libeigen3-dev \
    python3-dev \
#    python-dev \
    python3-numpy \
    unzip \
    libxml2-dev \
    libxslt-dev \
    libboost-atomic-dev \
    libboost-iostreams-dev \
    libboost-chrono-dev \
    libboost-date-time-dev \
    python3-cairo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

COPY swig-3.0.12.tar.gz /
RUN tar -xzf swig-3.0.12.tar.gz \
 && cd swig-3.0.12 \
 && ./configure --prefix=/usr \
 && make -j 4 \
 && make install \
 && cd ..

RUN apt-get update \
 && apt-get install --target-release buster \
      openjdk-8-jdk \
      ca-certificates-java \
      --assume-yes

COPY rdkit.zip /
RUN unzip rdkit.zip && rm rdkit.zip

RUN mkdir /rdkit/build
WORKDIR /rdkit/build

ENV RDBASE=/rdkit
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$RDBASE/lib
ENV PYTHONPATH=$PYTHONPATH:$RDBASE
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/rdkit/gmwrapper
ENV CPLUS_INCLUDE_PATH="$CPLUS_INCLUDE_PATH:/usr/include/python3.7/"

# RDK_OPTIMIZE_NATIVE=ON assumes container will be run on the same architecture on which it is built
RUN cmake -Wno-dev \
	-D BOOST_ROOT=/usr/local/ \
  -D RDK_INSTALL_INTREE=OFF \
  -D RDK_INSTALL_STATIC_LIBS=OFF \
  -D RDK_BUILD_INCHI_SUPPORT=ON \
  -D RDK_BUILD_AVALON_SUPPORT=ON \
  -D RDK_BUILD_PYTHON_WRAPPERS=ON \
  -D RDK_BUILD_CAIRO_SUPPORT=ON \
  -D RDK_USE_FLEXBISON=OFF \
  -D RDK_BUILD_THREADSAFE_SSS=ON \
  -D RDK_OPTIMIZE_NATIVE=ON \
  -D PYTHON_EXECUTABLE=/usr/bin/python3 \
  -D PYTHON_INCLUDE_DIR=/usr/include/python3.5 \
  -D PYTHON_NUMPY_INCLUDE_PATH=/usr/lib/python3/dist-packages/numpy/core/include \
  -D CMAKE_INSTALL_PREFIX=/usr \
  -D CMAKE_BUILD_TYPE=Release \
  -D RDK_BUILD_SWIG_WRAPPERS=ON \
  ..

RUN make -j $(nproc) \
 && make install

FROM debian:buster AS rdkit-env

# Copy rdkit installation from rdkit-build-env
COPY --from=rdkit-build-env /usr/lib/libRDKit* /usr/lib/
COPY --from=rdkit-build-env /usr/lib/cmake/rdkit/* /usr/lib/cmake/rdkit/
COPY --from=rdkit-build-env /usr/share/RDKit /usr/share/RDKit
COPY --from=rdkit-build-env /usr/include/rdkit /usr/include/rdkit
COPY --from=rdkit-build-env /usr/lib/python3/dist-packages/rdkit /usr/lib/python3/dist-packages/rdkit
