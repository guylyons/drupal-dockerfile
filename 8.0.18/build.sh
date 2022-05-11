#!/bin/bash
docker build -t guylyons/drupal:latest . --no-cache
docker push guylyons/drupal:latest
