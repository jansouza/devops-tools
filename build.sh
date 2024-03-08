#!/bin/bash
set -e

docker build -t devops-tools-img .
docker run -dit --name devops-tools devops-tools-img
docker ps