#!/bin/bash
docker build -t guylyons/drupal:9 . --no-cache
docker push guylyons/drupal:9
