#!/bin/bash
docker build -t guylyons/drupal:php7.4 . --no-cache
docker push guylyons/drupal:php7.4
