#!/bin/bash
set -e

export $(cat .env.default | grep -v ^# | xargs);

echo Starting services:
docker start $APP_NAME-mysql || docker run --name $APP_NAME-mysql -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD -e MYSQL_DATABASE=$DB_DATABASE -p $DB_PORT:$DB_PORT -d mysql
until mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -D $DB_DATABASE --silent -e "STATUS;"
do
  echo "Waiting for database connection..."
  sleep 5
done

echo Running tests:
mix test
