#!/bin/bash -x

# A pvc named "m2" is required by this pipeline 
# Creation of Jenkins PVC
kubectl apply -f jenkins-pvc.yaml
kubectl get pvc

# Add Helm repo
helm repo add stable https://kubernetes-charts.storage.googleapis.com/
helm repo add codecentric https://codecentric.github.io/helm-charts

helm repo update
helm repo list

# helm
helm list

# Setting up Nginx Ingress Controller
helm install nginx-ingress stable/nginx-ingress --set controller.publishService.enabled=true

# Setting up external-dns
helm install external-dns stable/external-dns -f externaldns-values.yaml

# Setting up Jenkins
#helm install jenkins -f jenkins/values.yaml codecentric/jenkins --version 1.6.0
#helm install jenkins -f jenkins-values.yaml codecentric/jenkins --set nodeSelector."kubernetes\\.io/hostname=pool-zqpsovm8t-3ceup" 
helm install jenkins -f jenkins/values.yaml codecentric/jenkins 

echo "username: <my_jenkins_admin_username>"
echo "password: <my_jenkins_admin_password>"


