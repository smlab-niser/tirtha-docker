#!/bin/bash

if [ ! -f /.docker_intialized ]; then
    # Your initialization script
    echo "Running first-time setup..."
    cp /tirtha-public/tirtha_bk/config/tirtha.nginx /etc/nginx/sites-available/tirtha 
    ln -s /etc/nginx/sites-available/tirtha /etc/nginx/sites-enabled/

    # rabbitmq
    service rabbitmq-server start
    rabbitmq-plugins enable rabbitmq_management
    rabbitmqctl add_user $RMQ_USER $RMQ_PWD
    rabbitmqctl add_vhost $RMQ_VHOST
    rabbitmqctl set_user_tags $RMQ_USER administrator
    rabbitmqctl set_permissions -p $RMQ_VHOST $RMQ_USER ".*" ".*" ".*"
    rabbitmqctl eval 'application:get_env(rabbit, consumer_timeout).'
    echo "consumer_timeout = 31556952000" | tee -a /etc/rabbitmq/rabbitmq.conf
    service rabbitmq-server restart

    # copying the  error templates
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/403.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/404.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/500.html /var/www/tirtha/errors/
    cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/503.html /var/www/tirtha/errors/

    # giving permissions
    chmod -R 755 /var/www/tirtha/
    chown -R $(whoami):$(whoami) /var/www/tirtha/

    # django configuration
    source /venv/bin/activate
    python /tirtha-public/tirtha_bk/manage.py makemigrations tirtha
    python /tirtha-public/tirtha_bk/manage.py collectstatic --no-input
    python /tirtha-public/tirtha_bk/manage.py migrate
    DJANGO_SUPERUSER_PASSWORD=$DJANGO_SUPERUSER_PASSWORD python /tirtha-public/tirtha_bk/manage.py createsuperuser --no-input --username $DJANGO_SUPERUSER_NAME --email "$DJANGO_SUPERUSER_EMAIL"
    # Create a flag to prevent re-execution
    touch /.docker_intialized
fi

cd /tirtha-public/tirtha_bk/
source /venv/bin/activate

# running celery in a tmux session
tmux new-session -d -s celery_session || tmux attach-session -t celery_session
tmux send-keys -t celery_session "celery -A tirtha worker -l INFO --max-tasks-per-child=1 -P threads --beat" C-m

# starting RabbitMQ for celery
service rabbitmq-server start

# starting the frontend | browse to 0.0.0.0:8000 in a browser
gunicorn --bind 0.0.0.0:$GUNICORN_PORT tirtha_bk.wsgi

exec "$@"
