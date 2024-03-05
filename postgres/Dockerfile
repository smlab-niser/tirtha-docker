# syntax=docker/dockerfile:1
# Path: postgres/Dockerfile

FROM postgres

WORKDIR /

# Copying the DB entrypoint script to the container
COPY ./init_db.sh /docker-entrypoint-initdb.d
RUN chmod +x /docker-entrypoint-initdb.d/init_db.sh
