FROM microblinkdev/centos-ninja:1.10.2 as ninja
FROM microblinkdev/centos-ccache:3.7.11 as ccache
FROM microblinkdev/centos-git:2.30.0 as git
FROM microblinkdev/centos-python:3.8.0 as python

FROM microblinkdev/centos-gcc:8.3.0

COPY --from=ninja /usr/local/bin/ninja /usr/local/bin/
COPY --from=python /usr/local /usr/local/
COPY --from=git /usr/local /usr/local/
COPY --from=ccache /usr/local /usr/local/

# install LFS and setup global .gitignore for both
# root and every other user logged with -u user:group docker run parameter
RUN yum -y install epel-release && \
    yum -y install openssh-clients glibc-static java-devel which gtk3-devel zip bzip2 make libXt libjpeg-devel openssl11-devel openblas-devel && \
    git lfs install && \
    echo "~*" >> /.gitignore_global && \
    echo ".DS_Store" >> /.gitignore_global && \
    echo "[core]" >> /root/.gitconfig && \
    echo "	excludesfile = /.gitignore_global" >> /root/.gitconfig && \
    cp /root/.gitconfig /.config && \
    git config --global user.email "developer@microblink.com" && \
    git config --global user.name "Developer" && \
    dbus-uuidgen > /etc/machine-id && \
    echo "bind '\"\\e[A\": history-search-backward'" >> ~/.bashrc && \
    echo "bind '\"\\e[B\": history-search-forward'" >> ~/.bashrc && \
    echo "bind \"set completion-ignore-case on\"" >> ~/.bashrc

ENV NINJA_STATUS="[%f/%t %c/sec] "  \
    JAVA_HOME=/usr

# support for conan packages to discover OpenSSL 1.1.1
ENV CONAN_CMAKE_CUSTOM_OPENSSL_ROOT_DIR=/usr/include/openssl11      \
    CONAN_CMAKE_CUSTOM_OPENSSL_LIBRARIES=/usr/lib64/openssl11       \
    CONAN_CMAKE_CUSTOM_OPENSSL_SSL_LIBRARY=/usr/lib64/openssl11     \
    CONAN_CMAKE_CUSTOM_OPENSSL_CRYPTO_LIBRARY=/usr/lib64/openssl11  \
    CONAN_CMAKE_CUSTOM_OPENSSL_INCLUDE_DIR=/usr/include/openssl11

# create gcc/g++ symlinks in /usr/bin (compatibility with legacy gcc conan profile)
# and also replace binutils tools with GCC version
RUN ln -s /usr/local/bin/gcc /usr/bin/gcc && \
    ln -s /usr/local/bin/g++ /usr/bin/g++ && \
    rm /usr/bin/nm /usr/bin/ranlib /usr/bin/ar && \
    ln -s /usr/local/bin/gcc-ar /usr/bin/ar && \
    ln -s /usr/local/bin/gcc-nm /usr/bin/nm && \
    ln -s /usr/local/bin/gcc-ranlib /usr/bin/ranlib && \
    rm /usr/local/bin/nm /usr/local/bin/ranlib /usr/local/bin/ar && \
    ln -s /usr/local/bin/gcc-ar /usr/local/bin/ar && \
    ln -s /usr/local/bin/gcc-nm /usr/local/bin/nm && \
    ln -s /usr/local/bin/gcc-ranlib /usr/local/bin/ranlib && \
    ln -s /usr/local/bin/ccache /usr/bin/ccache

ARG CMAKE_VERSION=3.19.3

# download and install CMake
RUN cd /home && \
    curl -o cmake.tar.gz -L https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-Linux-x86_64.tar.gz && \
    tar xf cmake.tar.gz && \
    cd cmake-${CMAKE_VERSION}-Linux-x86_64 && \
    find . -type d -exec mkdir -p /usr/local/\{} \; && \
    find . -type f -exec mv \{} /usr/local/\{} \; && \
    cd .. && \
    rm -rf *

ARG CONAN_VERSION=1.33.0

# download and install conan and grip
RUN python3 -m pip install conan==${CONAN_VERSION} grip

# download and install chrome and setup runner script
RUN cd /home && \
    curl -o chrome.rpm https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm && \
    yum -y install chrome.rpm && \
    rm chrome.rpm

# create development folders (mount points)
RUN mkdir -p /home/source           && \
    mkdir -p /home/build            && \
    mkdir -p /home/test-data        && \
    mkdir -p /home/secure-test-data && \
    chmod --recursive 777 /home
