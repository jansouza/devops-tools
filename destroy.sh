#!/bin/bash
set -e

docker stop devops-tools
docker rm devops-tools
docker rmi devops-tools
docker ps