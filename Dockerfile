FROM ubuntu:20.04

ARG UID=1000
ARG GID=1000

# add new sudo user
ENV USERNAME trex
ENV HOME /home/$USERNAME
RUN useradd -m $USERNAME && \
        echo "$USERNAME:$USERNAME" | chpasswd && \
        usermod --shell /bin/bash $USERNAME && \
        usermod -aG sudo $USERNAME && \
        mkdir /etc/sudoers.d && \
        echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/$USERNAME && \
        chmod 0440 /etc/sudoers.d/$USERNAME && \
        usermod  --uid $UID $USERNAME && \
        groupmod --gid $GID $USERNAME

# install package
RUN echo "Acquire::GzipIndexes \"false\"; Acquire::CompressionTypes::Order:: \"gz\";" > /etc/apt/apt.conf.d/docker-gzip-indexes
ENV DEBIAN_FRONTEND noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        sudo \
        less \
        emacs \
        tmux \
        bash-completion \
        command-not-found \
        software-properties-common \
        curl \
        coreutils \
        build-essential \
        git \
        git-lfs \
        python3-dev \
        python3-pip \
        python3-venv \
        libgl1-mesa-dev \
        graphviz \
        emacs \
        && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

USER $USERNAME
WORKDIR /home/$USERNAME
SHELL ["/bin/bash", "-l", "-c"]
RUN python3 -m venv env_trex && \
    source ~/env_trex/bin/activate && \
    python3 -m pip install wheel && \
    git clone https://github.com/NVIDIA/TensorRT.git -b 23.08 && \
    cd TensorRT/tools/experimental/trt-engine-explorer && \
    sed -i 's/jupyterlab/jupyterlab==3.6.5/g' requirements.txt && \
    echo "Werkzeug==2.2.3" >> requirements.txt && \
    echo "xarray==2022.3.0" >> requirements.txt && \
    echo "notebook==6.1.5" >> requirements.txt && \
    echo "requests==2.28" >> requirements.txt && \
    python3 -m pip install --no-warn-script-location -e . && \
    export PATH=$HOME/env_trex/bin:$PATH && \
    jupyter nbextension enable widgetsnbextension --user --py

RUN echo "source ~/env_trex/bin/activate" >> ~/.bashrc && \
    echo "export PATH=$HOME/env_trex/bin:$PATH" >> ~/.bashrc