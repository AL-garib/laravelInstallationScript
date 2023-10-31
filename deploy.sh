#!/bin/bash

GIT_URL=$1
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

npm install
npm run dev

composer_v=$(sed -n '11s/.*"\^\(.*\)\.5".*/\1/p' composer.json)

php_v=$(php -v | sed -n 's/PHP \([^ ]*\)[^A-Za-z].-.*/\1/p')

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
        sed -i "/DB_PASSWORD/c\DB_PASSWORD=root" $PATH_PROJECT"/.env"
        php artisan key:generate
fi


sudo chown -R www-data:www-data $PATH_PROJECT

php artisan storage:link
php artisan optimize:clear

