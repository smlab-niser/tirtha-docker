#!/bin/bash

if [ ! -f /.docker_intialized ]; then
    echo "Running first-time setup..."

    # Nginx
    cp /tirtha-public/tirtha_bk/config/tirtha.nginx /etc/nginx/sites-available/tirtha
    ln -s /etc/nginx/sites-available/tirtha /etc/nginx/sites-enabled/

    # RabbitMQ
    service rabbitmq-server start
    rabbitmq-plugins enable rabbitmq_management
    rabbitmqctl add_user $RMQ_USER $RMQ_PWD
    rabbitmqctl add_vhost $RMQ_VHOST
    rabbitmqctl set_user_tags $RMQ_USER administrator
    rabbitmqctl set_permissions -p $RMQ_VHOST $RMQ_USER ".*" ".*" ".*"
    rabbitmqctl eval 'application:get_env(rabbit, consumer_timeout).'
    echo "consumer_timeout = 31556952000" | tee -a /etc/rabbitmq/rabbitmq.conf
    service rabbitmq-server restart

    # Copying error templates
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/403.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/404.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/500.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/503.html /var/www/tirtha/errors/

    # Setting permissions on production directory
    chmod -R 755 /var/www/tirtha/
    chown -R $(whoami):$(whoami) /var/www/tirtha/

    # Django
    source /venv/bin/activate
    python /tirtha-public/tirtha_bk/manage.py makemigrations tirtha
    python /tirtha-public/tirtha_bk/manage.py collectstatic --no-input
    python /tirtha-public/tirtha_bk/manage.py migrate
    DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD python /tirtha-public/tirtha_bk/manage.py createsuperuser --no-input --username $DJANGO_SUPERUSER_NAME --email "$DJANGO_SUPERUSER_EMAIL"

    # Flag to prevent re-execution after container restart
    touch /.docker_intialized
fi

# Starting the backend
cd /tirtha-public/tirtha_bk/
source /venv/bin/activate

# Starting celery in a tmux session
tmux new-session -d -s celery_session || tmux attach-session -t celery_session
tmux send-keys -t celery_session "celery -A tirtha worker -l INFO --max-tasks-per-child=1 -P threads --beat --concurrency=1" C-m

# Starting RabbitMQ for celery
service rabbitmq-server start

# Starting the frontend | NOTE: Browse to HOST_IP:8000 in a browser to access the frontend
gunicorn --bind 0.0.0.0:$GUNICORN_PORT tirtha_bk.wsgi

exec "$@"
