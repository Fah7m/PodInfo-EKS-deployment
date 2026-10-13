#!/bin/bash
aws eks update-kubeconfig --region eu-west-2 --name eks-prod-eks-cluster --profile default

GRAFANA_PASS=$(aws ssm get-parameter --region eu-west-2 \
  --name /eks/prod/grafana/admin-password --with-decryption \
  --query Parameter.Value --output text)

kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin --from-literal=admin-password="$GRAFANA_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -


aws eks update-kubeconfig --name eks-prod-eks-cluster --region eu-west-2
VPC_ID=$(aws eks describe-cluster --name eks-prod-eks-cluster --region eu-west-2 \
  --query cluster.resourcesVpcConfig.vpcId --output text)

grep -q '^vpcId:' argocd/values/aws-load-balancer-controller.yaml   # fail if the line is missing
sed -i -E "s|^vpcId:.*|vpcId: ${VPC_ID}|" argocd/values/aws-load-balancer-controller.yaml

if ! git diff --quiet -- argocd/values/aws-load-balancer-controller.yaml; then
  git add argocd/values/aws-load-balancer-controller.yaml
  git commit -m "Set LBC vpcId to ${VPC_ID}"
  git push
fi

#secrets for argocd 

kubectl create secret generic argocd-secret \
  --from-literal=admin.password=$(htpasswd -bnBC 10 "" "admin" | tr -d ':\n') \
  --from-literal=admin.passwordMtime="$(date +%FT%T%Z)" \
  -n argocd


  kubectl get secrets -n argo-cd argocd-secret -o yaml | yq e '.data."admin.password"' - | base64 --decode