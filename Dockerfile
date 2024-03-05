# syntax=docker/dockerfile:1

# Base image
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# To avoid prompts during the build
ENV DEBIAN_FRONTEND=noninteractive

# Setting the working directory
WORKDIR /

# Stage 1: Main build process
# ==================================================================================================
# Installing dependencies
RUN apt-get update \
    && apt-get install -y \
        nano \
        curl \
        git \
        tmux \
        wget \
        unzip \
        libopencv-dev \
        libpq-dev \
        nginx \
        rabbitmq-server \
        python3.11-dev \
        python3.11-venv \
        python3-pip

# Cloning the Tirtha repository with the submodules
# NOTE: The `postBuffer` is set to 524288000 to avoid the RPC failed error
RUN git clone https://github.com/smlab-niser/tirtha-public.git
RUN cd /tirtha-public \
    && git config --global http.postBuffer 524288000 \
    && git submodule update --init --recursive

# Creating a Python virtual environment and installing dependencies
# NOTE: `protobuf==3.20.3` is needed for a component of ImageOps.
RUN python3.11 -m venv venv \
    && /venv/bin/pip install --upgrade pip setuptools wheel \
    && cd /tirtha-public \
    && /venv/bin/pip install -r ./requirements.txt --default-timeout=2000 \
    && /venv/bin/pip install -e /tirtha-public/tirtha_bk/nn_models/nsfw_model/ \
    && /venv/bin/pip install protobuf==3.20.3

# Getting the pre-trained checkpoints for ImageOps models
RUN wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/MR2021.1.0.zip \
    && unzip MR2021.1.0.zip \
    && mv ./bin21/ /tirtha-public/tirtha_bk/bin21/ \
    && rm ./MR2021.1.0.zip
RUN wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/ckpt_kadid10k.pt \
    && mv ./ckpt_kadid10k.pt /tirtha-public/tirtha_bk/nn_models/MANIQA/

# Setting up npm to install obj2gltf and gltfpack
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash
RUN . /root/.bashrc
    && nvm install node \
    && nvm use node \
    && npm install -g obj2gltf
RUN wget https://github.com/zeux/meshoptimizer/releases/download/v0.20/gltfpack-ubuntu.zip \
    && unzip gltfpack-ubuntu.zip \
    && chmod +x gltfpack \
    && mv gltfpack /usr/local/bin/ \
    && rm /gltfpack-ubuntu.zip

# Copying the configuration files to the appropriate locations
RUN mv /tirtha-public/tirtha_bk/config/tirtha.docker.nginx /tirtha-public/tirtha_bk/config/tirtha.nginx \
    && mv /tirtha-public/tirtha_bk/tirtha_bk/local_settings.docker.py /tirtha-public/tirtha_bk/tirtha_bk/local_settings.py \
    && mv /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.docker.py /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.py

# ==================================================================================================

# Stage 2: Final setup
# ==================================================================================================
# Copying the entrypoint executable from local system to the container
COPY ./start.sh /
RUN chmod +x /start.sh

# Copying the production folder to the container
COPY ./tirtha /var/www/tirtha

# Entrypoint to run the executable during container start
ENTRYPOINT [ "/start.sh" ]
# ==================================================================================================
