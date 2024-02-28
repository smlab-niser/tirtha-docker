# syntax=docker/dockerfile:1

# Stage 1: Base image
FROM nvidia/cuda:11.8.0-devel-ubuntu22.04

# create environment such that no prompt occurs during the build
ENV DEBIAN_FRONTEND=noninteractive

# create the working directory
WORKDIR /

# Install dependencies
RUN apt-get update \
    && apt-get install -y nano curl git tmux wget unzip libopencv-dev libpq-dev nginx rabbitmq-server python3.11-dev python3.11-venv python3-pip 

# Clone the tirtha repository and also get the submodules
RUN git clone https://github.com/smlab-niser/tirtha-public.git 
RUN cd /tirtha-public && git config --global http.postBuffer 524288000 && git submodule update --init --recursive 

# Initiate the python virtual environment and download the dependencies
# ---------------------------------------------------------------------------------
RUN python3.11 -m venv venv \
    && /venv/bin/pip install --upgrade pip setuptools wheel \
    && cd /tirtha-public \
    && /venv/bin/pip install -r ./requirements.txt --default-timeout=2000 \ 
    && /venv/bin/pip install -e /tirtha-public/tirtha_bk/nn_models/nsfw_model/ && /venv/bin/pip install protobuf==3.20.3 


RUN wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/MR2021.1.0.zip \
    && unzip MR2021.1.0.zip && mv ./bin21/ /tirtha-public/tirtha_bk/bin21/ && rm ./MR2021.1.0.zip  

RUN wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/ckpt_kadid10k.pt \
    && mv ./ckpt_kadid10k.pt /tirtha-public/tirtha_bk/nn_models/MANIQA/

RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.7/install.sh | bash

RUN . /root/.bashrc && nvm install node && nvm use node && npm install -g obj2gltf

RUN wget https://github.com/zeux/meshoptimizer/releases/download/v0.20/gltfpack-ubuntu.zip \
    && unzip gltfpack-ubuntu.zip && chmod +x gltfpack && mv gltfpack /usr/local/bin/ && rm /gltfpack-ubuntu.zip

RUN mv /tirtha-public/tirtha_bk/config/tirtha.docker.nginx /tirtha-public/tirtha_bk/config/tirtha.nginx \
    && mv /tirtha-public/tirtha_bk/tirtha_bk/local_settings.docker.py /tirtha-public/tirtha_bk/tirtha_bk/local_settings.py \
    && mv /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.docker.py /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.py
# ---------------------------------------------------------------------------------

# copy the entrypoint executable from local system to the container 
COPY ./start.sh /

# copy the tirtha folder to the container 
COPY ./tirtha /var/www/tirtha

# make it executable
RUN chmod +x /start.sh

# entrypoint to run the executable during start of the container
ENTRYPOINT [ "/start.sh" ]