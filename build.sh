#!/bin/bash
set -e

docker build --no-cache -t devops-tools .
docker run -dit --name devops-tools devops-tools
docker ps