#!/bin/bash

export GITHUB_USER=steve-fraser 
export REPO=gitops-docker-cluster-api
export MGMT_CLUSTER_NAME=cluster-manager   
export WORKLOAD_CLUSTER_NAME=my-cluster  


kind create cluster --name $MGMT_CLUSTER_NAME \
    --config kind_cluster_manager.yaml

clusterctl init --infrastructure docker

kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capd-system
kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capi-kubeadm-control-plane-system
kubectl wait --for=condition=ready --timeout=2m pod -l cluster.x-k8s.io/provider -n capi-kubeadm-bootstrap-system
kubectl wait --for=condition=ready --timeout=2m pod -l app.kubernetes.io/instance -n cert-manager

clusterctl generate cluster my-cluster --flavor development \
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

flux reconcile kustomization cluster-manager 

#kubectl wait --for=condition=ready --timeout=2m pod -l app.kubernetes.io/instance -n cert-manager

# kind export kubeconfig --name my-cluster

# kubectl --kubeconfig=./capi-quickstart.kubeconfig \
#   apply -f https://docs.projectcalico.org/v3.18/manifests/calico.yaml