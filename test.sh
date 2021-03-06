#!/bin/bash
set -e

export $(cat .env.default | grep -v ^# | xargs);

echo Starting services:
docker start $APP_NAME-mysql || docker run --name $APP_NAME-mysql -e MYSQL_ROOT_PASSWORD=$DB_PASSWORD -e MYSQL_DATABASE=$DB_DATABASE -p $DB_PORT:$DB_PORT -d mysql
until mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -D $DB_DATABASE --silent -e "STATUS;"
do
  echo "Waiting for database connection..."
  sleep 1
done

echo Running migrations:
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -D $DB_DATABASE < ./test/migrations/user.sql
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -D $DB_DATABASE < ./test/migrations/session.sql
mysql -h $DB_HOST -u $DB_USERNAME -p$DB_PASSWORD -D $DB_DATABASE < ./test/migrations/remember.sql

echo Running format:
mix format

echo Running tests:
mix test --trace
