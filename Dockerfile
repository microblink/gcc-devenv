FROM microblinkdev/centos-ninja:1.9.0 as ninja
FROM microblinkdev/centos-python:3.7.3 as python
FROM microblinkdev/centos-git:2.21.0 as git

FROM microblinkdev/centos-gcc:8.3.0

COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/
COPY --from=python /usr/local /usr/local/
COPY --from=git /usr/local /usr/local/

# install LFS and setup global .gitignore
RUN yum -y install openssh-clients && \
    git lfs install && \
    echo "~*" >> ~/.gitignore_global && \
    echo ".DS_Store" >> ~/.gitignore_global && \
    echo "[core]" >> ~/.gitconfig && \
    echo "	excludesfile = /root/.gitignore_global" >> ~/.gitconfig && \
    dbus-uuidgen > /etc/machine-id

ENV NINJA_STATUS="[%f/%t %c/sec] "

# create gcc/g++ symlinks in /usr/bin (compatibility with legacy gcc conan profile)
# and also replace binutils tools with GCC version
RUN ln -s /usr/local/bin/gcc /usr/bin/gcc && \
    ln -s /usr/local/bin/g++ /usr/bin/g++ && \
    rm /usr/bin/nm /usr/bin/ranlib /usr/bin/ar && \
    ln -s /usr/local/bin/gcc-ar /usr/bin/ar && \
    ln -s /usr/local/bin/gcc-nm /usr/bin/nm && \
    ln -s /usr/local/bin/gcc-ranlib /usr/bin/ranlib

ARG CMAKE_VERSION=3.14.3

# download and install CMake
RUN cd /home && \
    curl -o cmake.tar.gz -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz && \
    tar xf cmake.tar.gz && \
    cd cmake-${CMAKE_VERSION}-Linux-x86_64 && \
    find . -type d -exec mkdir -p /usr/local/\{} \; && \
    find . -type f -exec mv \{} /usr/local/\{} \; && \
    cd .. && \
    rm -rf *

ARG CONAN_VERSION=1.15.0

# download and install conan and LFS and set global .gitignore
RUN python3 -m pip install conan==${CONAN_VERSION}

# create development folders (mount points)
RUN mkdir -p /home/source           && \
    mkdir -p /home/build            && \
    mkdir -p /home/test-data        && \
    mkdir -p /home/secure-test-data && \
    mkdir -p ~/.conan
