#!/bin/bash

GIT_URL=$1

#config DATABASE
MYSQL_DATABASE=$2
MYSQL_USERNAME=$3
MYSQL_PASSWORD=$4



PROJECT_DIR="/var/www/html/"

cd $PROJECT_DIR

URL=$(awk -F/ '{sub(/\..*/,"",$NF); print $NF}' <<< $GIT_URL)
#echo $PROJECT_DIR$URL

PATH_PROJECT=$PROJECT_DIR$URL

if [ ! -d $PATH_PROJECT ]; then
        git clone $GIT_URL
else
        echo "is installed ${$PATH_PROJECT}"
fi



cd $PATH_PROJECT


composer_v=$(sed -n '/"php":/s/.*"\(.*\)\.\(.*\)".*/\1/p' composer.json | sed 's/\^//;s/,$//')

php_v=$(php -v | sed -n 's/PHP \([^ ]*\)[^A-Za-z].-.*/\1/p')

npm install
npm run dev

echo $php_v

if [[ $composer_v ==  $php_v ]]; then
        composer install --no-interaction --optimize-autoloader --no-dev
else
        sudo update-alternatives --set php /usr/bin/php${composer_v}
        composer update
        composer install --no-interaction --optimize-autoloader --no-dev
fi


if [ ! -f ".env" ]; then
        cp .env.example .env
        sed -i "/DB_DATABASE/c\DB_DATABASE=$MYSQL_DATABASE" $PATH_PROJECT"/.env"
        sed -i "/DB_USERNAME/c\DB_USERNAME=$MYSQL_USERNAME" $PATH_PROJECT"/.env"
        sed -i "/DB_PASSWORD/c\DB_PASSWORD=$MYSQL_PASSWORD" $PATH_PROJECT"/.env"
        php artisan key:generate
fi


sudo chown -R www-data:www-data $PATH_PROJECT

php artisan storage:link
php artisan optimize:clear

