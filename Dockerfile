ARG KATSDPDOCKERBASE_REGISTRY=quay.io/ska-sa

FROM $KATSDPDOCKERBASE_REGISTRY/docker-base-build as build

USER root
#RUN apt-get update && \
#    apt-get install -y gnome-todo apt-utils cmake make wget git

######################################################################

#Package dependencies
COPY apt.sources.list /etc/apt/sources.list

#Setup environment
ENV DDFACET_TEST_DATA_DIR /test_data
ENV DDFACET_TEST_OUTPUT_DIR /test_output

# Support large mlocks
RUN echo "*        -   memlock     unlimited" > /etc/security/limits.conf
ENV DEBIAN_FRONTEND noninteractive
ENV DEBIAN_PRIORITY critical
ENV GNUCOMPILER 7
ENV DEB_SETUP_DEPENDENCIES \
    dpkg-dev \
    g++-$GNUCOMPILER \
    gcc-$GNUCOMPILER \
    libc-dev \
    cmake \
    gfortran-$GNUCOMPILER \
    git \
    wget \
    subversion

RUN apt-get update
RUN apt-get install -y $DEB_SETUP_DEPENDENCIES

ENV DEB_DEPENCENDIES \
    python3-pip \
    libfftw3-dev \
    python3-numpy \
    libfreetype6 \
    libfreetype6-dev \
    libpng-dev \
    pkg-config \
    python3-dev \
    libboost-all-dev \
    libcfitsio-dev \
    libhdf5-dev \
    wcslib-dev \
    libatlas-base-dev \
    liblapack-dev \
    python3-tk \
    libreadline6-dev \
    subversion \
    liblog4cplus-dev \
    libhdf5-dev \
    libncurses5-dev \
    flex \
    bison \
    libbison-dev \
    make

RUN apt-get update
RUN apt-get install -y $DEB_DEPENCENDIES

#####################################################################
## BUILD CASACORE FROM SOURCE
#####################################################################
USER root

RUN mkdir /src
WORKDIR /src
RUN wget https://github.com/casacore/casacore/archive/v3.3.0.tar.gz
RUN tar xvf v3.3.0.tar.gz
RUN mkdir casacore-3.3.0/build
WORKDIR /src/casacore-3.3.0/build
RUN cmake -DCMAKE_INSTALL_PREFIX=/usr -DCMAKE_BUILD_TYPE=Release -DBUILD_DEPRECATED=ON -DBUILD_PYTHON=OFF -DBUILD_PYTHON3=ON ../
RUN make -j `nproc`
RUN make install
RUN ldconfig
WORKDIR /src
RUN rm v3.3.0.tar.gz
RUN wget https://github.com/casacore/python-casacore/archive/v3.3.0.tar.gz
RUN tar xvf v3.3.0.tar.gz
WORKDIR /src/python-casacore-3.3.0
RUN python3 -m pip install .
WORKDIR /
RUN python3 -c "from pyrap.tables import table as tbl"


#######################################################################

# Switch to Python 3 environment
USER kat
ENV PATH="$PATH_PYTHON3" VIRTUAL_ENV="$VIRTUAL_ENV_PYTHON3"

# Install dependencies
RUN python -m pip install --upgrade pip
RUN python -m pip install pip-tools==6.6.1 
COPY --chown=kat:kat requirements.txt /tmp/install/requirements.txt
#RUN install_pinned.py -r /tmp/install/requirements.txt
RUN pip install -r /tmp/install/requirements.txt

# Install the current package
COPY --chown=kat:kat . /tmp/install/katsdpbase
WORKDIR /tmp/install/katsdpbase
RUN python ./setup.py clean
RUN pip install --no-deps .
RUN pip check

#######################################################################

FROM $KATSDPDOCKERBASE_REGISTRY/docker-base-runtime
LABEL maintainer="sdpdev+katsdpbase@ska.ac.za"

COPY --from=build --chown=kat:kat /home/kat/ve3 /home/kat/ve3
ENV PATH="$PATH_PYTHON3" VIRTUAL_ENV="$VIRTUAL_ENV_PYTHON3"

RUN mkdir -p /home/kat/data
VOLUME ["/home/kat/data"]

USER kat
WORKDIR /home/kat/data
# Run run.sh and then go to interactive shell
#CMD ["/bin/bash", "--rcfile", "/run.sh", "-i"]

#ENTRYPOINT ["/bin/bash", "-c", "-i"]
#CMD ["python", "mvftoms.py"]
