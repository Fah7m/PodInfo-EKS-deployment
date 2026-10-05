#!/bin/bash
aws eks update-kubeconfig --region eu-west-2 --name eks-prod-eks-cluster --profile default

# argocd installation and helm installation






#secrets for argocd 

kubectl create secret generic argocd-secret \
  --from-literal=admin.password=$(htpasswd -bnBC 10 "" "admin" | tr -d ':\n') \
  --from-literal=admin.passwordMtime="$(date +%FT%T%Z)" \
  -n argocd


  kubectl get secrets -n argo-cd argocd-secret -o yaml | yq e '.data."admin.password"' - | base64 --decode