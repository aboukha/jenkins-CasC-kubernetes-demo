#!/bin/bash -x

helm uninstall jenkins
kubectl delete pvc m2
kubectl get pvc
