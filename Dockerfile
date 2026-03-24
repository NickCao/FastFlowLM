ARG BASE_IMAGE=ubuntu:26.04
ARG UBUNTU_PPA=""
ARG BACKPORTS=""
FROM ${BASE_IMAGE} AS buildenv

LABEL org.opencontainers.image.description="FastFlowLM build environment with all dependencies pre-installed"
LABEL org.opencontainers.image.source="https://github.com/FastFlowLM/FastFlowLM"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_PPA
ARG BACKPORTS

# Set up PPA if needed
RUN if [ -n "$UBUNTU_PPA" ]; then \
        apt update && apt install -y software-properties-common && \
        add-apt-repository -y "$UBUNTU_PPA"; \
    fi

# setup backports if needed
RUN if [ -n "$BACKPORTS" ]; then \
        echo "deb http://deb.debian.org/debian $BACKPORTS main" >> /etc/apt/sources.list; \
        apt update; \
        apt install -t $BACKPORTS -y libxrt-dev; \
    fi

# Install all build dependencies
RUN apt update && apt install -y \
    build-essential \
    cargo \
    cmake \
    debhelper-compat \
    dpkg-dev \
    fakeroot \
    git \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libboost-dev \
    libboost-program-options-dev \
    libcurl4-openssl-dev \
    libdrm-dev \
    libfftw3-dev \
    libreadline-dev \
    libswresample-dev \
    libswscale-dev \
    libxrt-dev \
    ninja-build \
    patchelf \
    pkg-config \
    rustc \
    uuid-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["/bin/bash"]


FROM buildenv AS build

RUN --mount=type=bind,target=/workspace/FastFlowLM,rw \
  cmake -B /workspace/build -S /workspace/FastFlowLM/src --preset linux-default && \
  ninja -C /workspace/build -j $(nproc) && \
  ninja -C /workspace/build -j $(nproc) install


FROM ${BASE_IMAGE} AS runtime

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive
ARG UBUNTU_PPA
ARG BACKPORTS

# Set up PPA if needed
RUN if [ -n "$UBUNTU_PPA" ]; then \
        apt update && apt install -y software-properties-common && \
        add-apt-repository -y "$UBUNTU_PPA"; \
    fi

# setup backports if needed
RUN if [ -n "$BACKPORTS" ]; then \
        echo "deb http://deb.debian.org/debian $BACKPORTS main" >> /etc/apt/sources.list; \
        apt update; \
        apt install -t $BACKPORTS -y libxrt-dev; \
    fi

# Install all runtime dependencies
RUN apt update && apt install -y \
    libxrt2 \
    libavformat62 \
    libswscale9 \
    libcurl4t64 \
    libboost-program-options1.90.0 \
    libfftw3-single3 \
    libreadline8t64 \
    && rm -rf /var/lib/apt/lists/*

COPY --from=build /opt/fastflowlm /opt/fastflowlm
