#!/bin/bash

set -e
echo $(date)

if [ ! -f /tmp/fpmlock ]
then
    touch /tmp/fpmlock
    chmod 666 /tmp/fpmlock
fi

PROJECT_COMPOSER='php /usr/local/bin/composer'
PROJECT_PHP='php'
PROJECT_PHP_FPM='php8.3-fpm'
PROJECT_SITE_BRANCH='main'
PROJECT_SITE_PATH='/var/www/html'
PROJECT_SITE_USER='www-data'


cd $PROJECT_SITE_PATH
git pull origin $PROJECT_SITE_BRANCH

$PROJECT_COMPOSER install --no-dev --no-interaction --prefer-dist --optimize-autoloader

( flock -w 10 9 || exit 1
   echo 'Restarting FPM...'; sudo -S service $PROJECT_PHP_FPM reload ) 9>/tmp/fpmlock

if [ -f artisan ]; then
    $PROJECT_PHP artisan migrate --force
fi

$PROJECT_PHP artisan cache:clear
$PROJECT_PHP artisan view:clear

$PROJECT_PHP artisan config:cache
$PROJECT_PHP artisan view:cache