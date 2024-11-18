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
VERSION="1.4"

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
      --path=*) DEPLOY_PATH="${1#*=}"; shift 1;; # string
      *) usage "Unknown option: ${1}"; exit 1;;
    esac
  done

  if test -z "${DEPLOY_APP}"; then
    usage 'Missing argument: <app> are required.'
    exit 1
  fi

  if test -z "${DEPLOY_PATH}"; then
    usage 'Missing argument: <path> are required.'
    exit 1
  fi

  echo "DEPLOY_APP: $DEPLOY_APP"
  echo "DEPLOY_IMAGE: $DEPLOY_IMAGE"
  echo "DEPLOY_PATH: $DEPLOY_PATH"
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

  # Check if File Exist
  if [ -f $DEPLOY_PATH/deployment.yaml ]; then
    DEPLOY_FILE="$DEPLOY_PATH/deployment.yaml"
  elif [ -f $DEPLOY_PATH/daemonset.yaml ]; then
    DEPLOY_FILE="$DEPLOY_PATH/daemonset.yaml"
  elif [ -f $DEPLOY_PATH/statefulset.yaml ]; then
    DEPLOY_FILE="$DEPLOY_PATH/statefulset.yaml"
  else
    echo "Deploy file (deployment.yaml, daemonset.yaml or statefulset.yaml) not found in path: $DEPLOY_PATH"
    exit 1
  fi

  echo "[Get metadata Info]"
  echo "DEPLOY_FILE: $DEPLOY_FILE"
  DEPLOY_KIND=$(kubectl get -f $DEPLOY_FILE -o json|jq -r '.kind')
  DEPLOY_NAME=$(kubectl get -f $DEPLOY_FILE -o json|jq -r '.metadata.name')
  DEPLOY_NAMESPACE=$(kubectl get -f $DEPLOY_FILE -o json|jq -r '.metadata.namespace')
  
  if [[ "$DEPLOY_KIND" == "DaemonSet" ]]; then
    DEPLOY_TYPE="daemonset"
  elif [[ "$DEPLOY_KIND" == "Deployment" ]]; then
    DEPLOY_TYPE="deployment"
  elif [[ "$DEPLOY_KIND" == "StatefulSet" ]]; then
    DEPLOY_TYPE="statefulset"
  else
    echo "DEPLOY_KIND: $DEPLOY_KIND not found (DaemonSet, Deployment, StatefulSet)"
    exit 1
  fi

  echo "  DEPLOY_TYPE=$DEPLOY_TYPE"
  echo "  DEPLOY_FILE=$DEPLOY_FILE"
  echo "  DEPLOY_APP=$DEPLOY_APP"
  echo "  DEPLOY_KIND=$DEPLOY_KIND"
  echo "  DEPLOY_NAME=$DEPLOY_NAME"
  echo "  DEPLOY_NAMESPACE=$DEPLOY_NAMESPACE"

  # Change Image
  if [ -n "${DEPLOY_IMAGE}" ];then
    echo "[Change Image]"
    echo "  sed -i "s@image.*@image: ${DEPLOY_IMAGE}@" $DEPLOY_FILE"
    sed -i "s@image.*@image: ${DEPLOY_IMAGE}@" $DEPLOY_FILE
    if [ "$?" -ne 0 ]; then
      echo "Error to set Image registry"
      exit 1
    fi
  fi

  # Execute kubectl apply
  echo "[kubectl apply]"
  DEPLOY_CONFIGMAP_FILE=$DEPLOY_PATH/config.yaml
  DEPLOY_SERVICE_FILE=$DEPLOY_PATH/service.yaml
  DEPLOY_INGRESS_FILE=$DEPLOY_PATH/ingress.yaml
  DEPLOY_CRONJOB_FILE=$DEPLOY_PATH/cronjob.yaml

  declare -a FILES=("$DEPLOY_FILE" "$DEPLOY_CONFIGMAP_FILE" "$DEPLOY_SERVICE_FILE" "$DEPLOY_INGRESS_FILE" "$DEPLOY_CRONJOB_FILE")
  for FILE in "${FILES[@]}"
  do
    if [ -f $FILE ]; then
      echo "  kubectl apply -f $FILE"
      kubectl apply -f $FILE
      if [ "$?" -ne 0 ]; then
        echo "Error to Deploy file - $FILE"
        exit 1
      fi
    fi
  done

  # Config Folders
  if [ -d $DEPLOY_PATH/config ];then
    kubectl delete configmap $DEPLOY_NAME-config -n $DEPLOY_NAMESPACE
    kubectl create configmap $DEPLOY_NAME-config --from-file=$DEPLOY_PATH/config -n $DEPLOY_NAMESPACE
  fi
    
  # Execute kubectl rollout
  echo "[kubectl rollout]"
  echo "  kubectl rollout restart $DEPLOY_TYPE $DEPLOY_NAME -n $DEPLOY_NAMESPACE"
  kubectl rollout restart $DEPLOY_TYPE $DEPLOY_NAME -n $DEPLOY_NAMESPACE
  if [ "$?" -ne 0 ]; then
    echo "Error to kubectl rollout restart"
    exit 1
  fi

  #echo "Get rollout status"
  kubectl rollout status $DEPLOY_TYPE $DEPLOY_NAME -n $DEPLOY_NAMESPACE
  if [ "$?" -ne 0 ]; then
    echo "Error to kubectl rollout status"
    exit 1
  fi

  #echo "List POD"
  kubectl get pods --selector app=$DEPLOY_APP -n $DEPLOY_NAMESPACE

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