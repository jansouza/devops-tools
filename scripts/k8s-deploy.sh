#!/bin/bash
# uncomment to debug the script
# set -x

## @file k8s-deploy.sh
## @author Jan Souza <me@jansouza.com>
## @copyright
## @brief Deploy Application to K8s Cluster
##

#
## Global variables
#################
SCRIPT_NAME=k8s-deploy.sh
VERSION="1.1"

#
## Script
#################

function handle_arguments() {
  # Ensure we have arguments
  if test "${#}" -eq 0; then
   usage
   exit 1
  fi

  while test "${#}" -gt 0; do
    case "${1}" in
      --app=*) DEPLOY_APP="${1#*=}"; shift 1;; # string
      --image=*) DEPLOY_IMAGE="${1#*=}"; shift 1;; # string
      --path=*) DEPLOYMENT_PATH="${1#*=}"; shift 1;; # string
      *) usage "Unknown option: ${1}"; exit 1;;
    esac
  done

  if test -z "${DEPLOY_APP}"; then
    usage 'Missing argument: <app> are required.'
    exit 1
  fi
  
  #if test -z "${DEPLOY_IMAGE}"; then
  #  usage 'Missing argument: <image> are required.'
  #  exit 1
  #fi

  if test -z "${DEPLOYMENT_PATH}"; then
    usage 'Missing argument: <path> are required.'
    exit 1
  fi

  echo "DEPLOY_APP: $DEPLOY_APP"
  echo "DEPLOY_IMAGE: $DEPLOY_IMAGE"
  echo "DEPLOYMENT_PATH: $DEPLOYMENT_PATH"
}

function usage() {
  local usage_message
  usage_message="$(printf 'Error: \n\t%s\nUsage: %s --app=<app> --image=<image> --path=<path>' "${1:-No argument provided}" "${SCRIPT_NAME}")"

  echo "${usage_message}" ''
}

function deploy(){
  echo "--------------"
  echo "K8s - DEPLOY"
  echo "--------------"

  DEPLOYMENT_FILE="$DEPLOYMENT_PATH/deployment.yaml"
  
  # Check if File Exist
  if [ ! -f $DEPLOYMENT_FILE ]; then
    echo "DEPLOYMENT_FILE not found"
    exit 1
  fi

  echo "[Get Deployment Info]"
  DEPLOYMENT_NAME=$(kubectl get -f $DEPLOYMENT_FILE -o json|jq -r '.metadata.name')
  NAMESPACE=$(kubectl get -f $DEPLOYMENT_FILE -o json|jq -r '.metadata.namespace')

  echo "  DEPLOY_APP=$DEPLOY_APP"
  echo "  DEPLOYMENT_NAME=$DEPLOYMENT_NAME"
  echo "  NAMESPACE=$NAMESPACE"

  # Change Image
  if [ -n "${DEPLOY_IMAGE}" ];then
    echo "[Change Image]"
    echo "  sed -i "s@image.*@image: ${DEPLOY_IMAGE}@" $DEPLOYMENT_FILE"
    sed -i "s@image.*@image: ${DEPLOY_IMAGE}@" $DEPLOYMENT_FILE
    if [ "$?" -ne 0 ]; then
      echo "Error to set Image registry"
      exit 1
    fi
  fi

  # Execute kubectl apply
  echo "[kubectl apply]"
  CONFIGMAP_FILE=$DEPLOYMENT_PATH/config.yaml
  SERVICE_FILE=$DEPLOYMENT_PATH/service.yaml
  INGRESS_FILE=$DEPLOYMENT_PATH/ingress.yaml
  CRONJOB_FILE=$DEPLOYMENT_PATH/cronjob.yaml

  declare -a FILES=("$DEPLOYMENT_FILE" "$CONFIGMAP_FILE" "$SERVICE_FILE" "$INGRESS_FILE" "$CRONJOB_FILE")
  for FILE in "${FILES[@]}"
  do
    if [ -f $FILE ]; then
      echo "  kubectl apply -f $FILE"
      kubectl apply -f $FILE
      if [ "$?" -ne 0 ]; then
        echo "Error to Deploy Application - $FILE"
        exit 1
      fi
    fi
  done

  # Config Folders
  if [ -d $DEPLOYMENT_PATH/config ];then
    kubectl delete configmap $DEPLOYMENT_NAME-config -n $NAMESPACE
    kubectl create configmap $DEPLOYMENT_NAME-config --from-file=$DEPLOYMENT_PATH/config -n $NAMESPACE
  fi
    
  # Execute kubectl rollout
  echo "[kubectl rollout]"
  echo "  kubectl rollout restart deployment $DEPLOYMENT_NAME -n $NAMESPACE"
  kubectl rollout restart deployment $DEPLOYMENT_NAME -n $NAMESPACE
  if [ "$?" -ne 0 ]; then
    echo "Error to kubectl rollout restart"
    exit 1
  fi

  #echo "Get rollout status"
  kubectl rollout status deployment $DEPLOYMENT_NAME -n $NAMESPACE
  if [ "$?" -ne 0 ]; then
    echo "Error to kubectl rollout status"
    exit 1
  fi

  #echo "List POD"
  kubectl get pods --selector app=$DEPLOY_APP -n $NAMESPACE

  echo "All done"
  exit 0
}

function main() {
    echo "============================================"
    echo "Date: $(date +'%m-%d-%Y %H:%M:%S')"
    
    handle_arguments "${@}"
    
    deploy
    exit 0
}

###############################################################################
# Will call main() with arguments passed on command line.
main "${@}"