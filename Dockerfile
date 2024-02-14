# syntax=docker/dockerfile:1

# Stage 1: Base image
FROM postgres

ENV DEBIAN_FRONTEND=noninteractive POSTGRES_PASSWORD=test1234

WORKDIR /

# Install dependencies
RUN apt-get update \
    && apt-get install -y git tmux nala libpq-dev python3.11-dev nginx rabbitmq-server libpq-dev python3.11-venv

RUN git clone https://github.com/smlab-niser/tirtha-public.git && cd /tirtha-public && git submodule update --init --recursive 
RUN python3.11 -m venv venv \
    && nala install -y python3-pip && /venv/bin/pip install --upgrade pip setuptools wheel \
    && cd /tirtha-public && /venv/bin/pip install -r ./requirements.txt --default-timeout=2000 \ 
    && /venv/bin/pip install -e /tirtha-public/tirtha_bk/nn_models/nsfw_model/ && /venv/bin/pip install protobuf==3.20.3 && nala install -y wget unzip && wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/MR2021.1.0.zip \
    && unzip MR2021.1.0.zip && mv ./bin21/ /tirtha-public/tirtha_bk/bin21/ && rm ./MR2021.1.0.zip && wget https://smlab.niser.ac.in/project/tirtha/static/artifacts/ckpt_kadid10k.pt \
    && mv ./ckpt_kadid10k.pt /tirtha-public/tirtha_bk/nn_models/MANIQA/

RUN nala install -y npm systemctl nano && npm install -g obj2gltf && wget https://github.com/zeux/meshoptimizer/releases/download/v0.20/gltfpack-ubuntu.zip \
    && unzip gltfpack-ubuntu.zip && chmod +x gltfpack && mv gltfpack /usr/local/bin/ && rm /gltfpack-ubuntu.zip

RUN mv /tirtha-public/tirtha_bk/config/tirtha.docker.nginx /tirtha-public/tirtha_bk/config/tirtha.nginx \
    && mv /tirtha-public/tirtha_bk/tirtha_bk/local_settings.docker.py /tirtha-public/tirtha_bk/tirtha_bk/local_settings.py \
    && mv /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.docker.py /tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.py

# COPY ./tirtha-public/tirtha_bk/gunicorn/gunicorn.conf.py /tirtha-public/tirtha_bk/gunicorn/    

COPY ./init_db.sh /docker-entrypoint-initdb.d
# COPY ./tirtha /var/www/tirtha 
COPY ./start.sh /

RUN chmod +x /docker-entrypoint-initdb.d/init_db.sh && chmod +x /start.sh