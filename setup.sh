#!/bin/bash

export GITHUB_USER=steve-fraser 
export REPO=gitops-docker-cluster-api
export MGMT_CLUSTER_NAME=cluster-manager   


kind create cluster --name $MGMT_CLUSTER_NAME \
    --config kind_cluster_manager.yaml

clusterctl init --infrastructure docker

clusterctl generate cluster capi-quickstart --flavor development \
  --kubernetes-version v1.22.0 \
  --control-plane-machine-count=1 \
  --worker-machine-count=1 \
  > cluster-api-system/cluster.yaml

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$REPO \
  --branch=main \
  --path=./clusters/$MGMT_CLUSTER_NAME \
  --personal \
  --read-write-key

