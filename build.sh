#!/bin/bash
#set -e

docker_path=$(command -v docker)
if [ -x "$docker_path" ]; then
    ENGINE="docker"
else
    podman_path=$(command -v podman)
    if [ -x "$podman_path" ]; then
        ENGINE="podman"
    else
        echo "No container engine found; Install docker or podman"
        exit 1
    fi
fi  

echo $ENGINE
export TARGETPLATFORM=$(uname -m)
$ENGINE build -t devops-tools --build-arg TARGETPLATFORM=$TARGETPLATFORM --no-cache . || true
$ENGINE run -dit --name devops-tools devops-tools || true
$ENGINE ps