#!/bin/bash
docker build -t guylyons/drupal:8 . --no-cache
docker push guylyons/drupal:8
