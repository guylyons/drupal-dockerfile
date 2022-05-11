#!/bin/bash
docker build -t guylyons/drupal:latest .
docker push guylyons/drupal:latest
