#!/bin/bash
set -e

docker build -t devops-tools .
docker run -dit --name devops-tools devops-tools
docker ps