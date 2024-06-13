# Our AIO builder docker file
FROM debian:12

RUN mkdir /repo
COPY ./scripts/vars.sh /vars.sh
COPY ./scripts/docker/setup_mkimage.sh /setup_mkimage.sh

RUN apt-get update && apt-get install -yq \
    autoconf \
    bc \
    binfmt-support \
    bison \
    bsdextrautils \
    build-essential \
    cpio \
    curl \
    debootstrap \
    debhelper \
    device-tree-compiler \
    dosfstools \
    dwarves \
    fakeroot \
    flex \
    genext2fs \
    git \
    kmod \
    kpartx \
    libconfuse-common \
    libconfuse-dev \
    libdbus-1-dev \
    libelf-dev \
    libglib2.0-dev \
    libical-dev \
    libncurses-dev \
    libreadline-dev \
    libssl-dev \
    libudev-dev \
    lvm2 \
    mtools \
    parted \
    pkg-config \
    python3-dev \
    python3-pyelftools \
    python3-setuptools \
    qemu-utils \
    qemu-user-static \
    rsync \
    swig \
    u-boot-tools \
    unzip \
    uuid-runtime \
    wget \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* \
    && /setup_mkimage.sh \
    && rm /setup_mkimage.sh \
    && curl -fsSL "https://go.dev/dl/go1.22.4.linux-amd64.tar.gz" -o golang.tar.gz \
    && tar -C /usr/local -xzf golang.tar.gz \
    && rm golang.tar.gz \
    && for bin in `ls /usr/local/go/bin/`; do \
        update-alternatives --install "/usr/bin/$bin" "$bin" "/usr/local/go/bin/$bin" 1; \
        update-alternatives --set "$bin" "/usr/local/go/bin/$bin"; \
    done