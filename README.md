# Docker Config for [Project Tirtha](https://github.com/smlab-niser/tirtha-public)

>[!warning]
> The image sizes are large and downloading packages takes the most time during the build process. On a stable 100 Mbps connection, the build process takes around 30-40 minutes.
> | Image   |  Size   |
> | ------------ | ------- |
> | `tirtha-web`  | 21.1 GB  |
> | `tirtha-db`    | 0.431 GB |

---

## Requirements
* Docker [engine](https://docs.docker.com/engine/install/) and [compose](https://docs.docker.com/compose/install/). 
* Nvidia drivers installed.
* [Nvidia container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).

## Build steps
* Clone the repository and `cd` into the directory:
    ```sh
    git clone https://github.com/smlab-niser/tirtha-docker.git && cd tirtha-docker
    ```
* Edit the [`docker.env`](https://github.com/smlab-niser/tirtha-docker/blob/main/docker.env) file to set the environment variables as per your requirements. In case, you are setting up Tirtha on a remote server, you need to set the `HOST_IP` to the IP address of the server. Also, set the `DEBUG` variable to `False`, if you are configuring Tirtha for production.
* The containers will use ports 8000 (for gunicorn), 15672 (for RabbitMQ), and 8001 (for Postgres) on the host system. Ensure these ports are free on the host.
* Run the following command to build the images:
    ```sh
    sudo docker-compose up
    ```
* After the build is complete, the containers can be attached using the following command:
    ```sh
    sudo docker exec -it container_name
    ```
    To find the `container_name`, use the following command:
    ```sh
    sudo docker ps
    ```
* The Tirtha web interface can be accessed at `http://localhost:8000` or `http://<HOST_IP>:8000` if you are setting up Tirtha on a remote server. To access the Django admin interface, use `http://localhost:8000/admin` or `http://<HOST_IP>:8000/admin`. The default username and password can be found in the `docker.env` file.
* To access Tirtha-related logs, check the `/var/www/tirtha/logs/` directory. Logs for system packages, like RabbitMQ, can be accessed using `journalctl`. Postgres logs are available using `sudo docker logs --details container_name`.
