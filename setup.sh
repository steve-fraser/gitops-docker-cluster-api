#!/bin/bash

export GITHUB_USER=steve-fraser 
export REPO=gitops-docker-cluster-api
export MGMT_CLUSTER_NAME=cluster-manager   
export WORKLOAD_CLUSTER_NAME=my-cluster  



if ! command -v kind &> /dev/null
then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.11.1/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
fi

kind create cluster --name $MGMT_CLUSTER_NAME \
    --config kind_cluster_manager.yaml

clusterctl init --infrastructure docker

kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capd-system
kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capi-kubeadm-control-plane-system
kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capi-kubeadm-bootstrap-system
kubectl wait --for=condition=ready --timeout=2m pod -l app.kubernetes.io/instance -n cert-manager

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$REPO \
  --branch=main \
  --path=./clusters/$MGMT_CLUSTER_NAME \
  --personal \
  --read-write-key

flux reconcile kustomization cluster-manager 

kubectl wait --for=condition=ready --timeout=2m cluster -l cluster=$WORKLOAD_CLUSTER_NAME

kind export kubeconfig --name $WORKLOAD_CLUSTER_NAME

kubectl apply -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml

flux bootstrap github \
  --owner=$GITHUB_USER \
  --repository=$REPO \
  --branch=main \
  --path=./clusters/$WORKLOAD_CLUSTER_NAME \
  --personal \
  --read-write-key