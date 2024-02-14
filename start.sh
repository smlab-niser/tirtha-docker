# 
cp /tirtha-public/tirtha_bk/config/tirtha.nginx /etc/nginx/sites-available/tirtha 
ln -s /etc/nginx/sites-available/tirtha /etc/nginx/sites-enabled/
systemctl enable rabbitmq-server
systemctl start rabbitmq-server
rabbitmq-plugins enable rabbitmq_management
rabbitmqctl add_user rmqtirthauser rmqtirthapwd
rabbitmqctl add_vhost rmqtirtha
rabbitmqctl set_user_tags rmqtirthauser administrator
rabbitmqctl set_permissions -p rmqtirtha rmqtirthauser ".*" ".*" ".*"
rabbitmqctl eval 'application:get_env(rabbit, consumer_timeout).'
echo "consumer_timeout = 31556952000" | tee -a /etc/rabbitmq/rabbitmq.conf
systemctl restart rabbitmq-server
cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/403.html /var/www/tirtha/errors/
cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/404.html /var/www/tirtha/errors/
cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/500.html /var/www/tirtha/errors/
cp tirtha-public/tirtha_bk/tirtha/templates/tirtha/503.html /var/www/tirtha/errors/
chmod -R 755 /var/www/tirtha/
chown -R $(whoami):$(whoami) /var/www/tirtha/
source /venv/bin/activate
python /tirtha-public/tirtha_bk/manage.py makemigrations tirtha
python /tirtha-public/tirtha_bk/manage.py collectstatic
python /tirtha-public/tirtha_bk/manage.py migrate