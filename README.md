## Docker support for [Project Tirtha](https://github.com/smlab-niser/tirtha-public)


1. Requirements:
    * Docker [engine](https://docs.docker.com/engine/install/) and [compose](https://docs.docker.com/compose/install/). 
    * Nvidia drivers installed. 
    * [Nvidia container toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html).


2. Size of the image is: 

   | REPOSITORY   |  SIZE   |
   | ------------ | ------- |
   | tirtha-web   | 21.1GB  |
   | tirtha-db    | 431MB   |


3. Steps to build the image: 

    3.1 User can change the environment variables such as the IP of the host machine, and database configuration. Important is change of Host Ip if user is trying to use the dockerfile through the ssh session. NOTE: By default, if user is using this in host pc itself  nothing is required to change and password can be seen in the environment file.

    3.2 Use following command ```sudo docker compose up```, to build and run the image tirtha-web and tirtha-deb. 

    3.3 After image build is complete, user can attach the shell with either of the containers. For the web-site tirtha-web container is required. And it can be attached with the this command. ```sudo docker exec -it tirtha-web-1 bash```


4. Users can check Tirtha-related logs at /var/www/tirtha/logs/ and logs for system packages, like RabbitMQ, using journalctl. Postgres logs are available using ```sudo docker logs --details container_name```.


5. Docker container will use ports 8000(gunicorn), 15672(rabbitmq) and 5432(postgres) on the host system. Ensure these ports are free on the host system. 