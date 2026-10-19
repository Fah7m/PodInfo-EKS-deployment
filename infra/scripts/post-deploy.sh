# One-time per machine (htpasswd makes the bcrypt hash)
sudo apt install -y apache2-utils

# 1. Point kubectl at the cluster
aws eks update-kubeconfig --name eks-prod-eks-cluster --region eu-west-2
kubectl get nodes

# 2. New VPC ID into the LBC values, pushed so ArgoCD sees it (before step 5)
VPC_ID=$(aws eks describe-cluster --name eks-prod-eks-cluster --region eu-west-2 \
  --query cluster.resourcesVpcConfig.vpcId --output text); echo $VPC_ID
sed -i -E "s|^vpcId:.*|vpcId: ${VPC_ID}|" argocd/values/aws-load-balancer-controller.yaml
git diff --stat
git add argocd/values/aws-load-balancer-controller.yaml
git commit -m "Set LBC vpcId" && git push

# 3. Grafana admin secret from SSM
GRAFANA_PASS=$(aws ssm get-parameter --region eu-west-2 --name /eks/prod/grafana/admin-password \
  --with-decryption --query Parameter.Value --output text)
kubectl create namespace monitoring --dry-run=client -o yaml | kubectl apply -f -
kubectl -n monitoring create secret generic grafana-admin-secret \
  --from-literal=admin-user=admin --from-literal=admin-password="$GRAFANA_PASS" \
  --dry-run=client -o yaml | kubectl apply -f -

# 4. Install ArgoCD with the password from SSM
ARGOCD_PASS=$(aws ssm get-parameter --region eu-west-2 --name /eks/prod/argocd/admin-password \
  --with-decryption --query Parameter.Value --output text)
ARGOCD_HASH=$(htpasswd -nbBC 10 "" "$ARGOCD_PASS" | tr -d ':\n' | sed 's/^\$2y/\$2a/')
helm repo add argo https://argoproj.github.io/argo-helm && helm repo update
helm upgrade --install argocd argo/argo-cd -n argocd --create-namespace \
  -f argocd/values/argocd.yaml \
  --set-string configs.secret.argocdServerAdminPassword="$ARGOCD_HASH" \
  --wait --timeout 10m
kubectl -n argocd delete secret argocd-initial-admin-secret --ignore-not-found

# 5. Hand off to GitOps (private repo? apply your repo-credentials Secret first)
kubectl apply -f argocd/root-app.yaml
kubectl get applications -n argocd -w



#### teardown #####

# 0. Save the VPC ID now (the cluster won't be there to ask later)
VPC_ID=$(aws eks describe-cluster --name eks-prod-eks-cluster --region eu-west-2 \
  --query cluster.resourcesVpcConfig.vpcId --output text); echo $VPC_ID

# 1. Remove ArgoCD (strip finalizers first so nothing waits on it)
for a in $(kubectl get applications -n argocd -o name); do
  kubectl patch $a -n argocd --type merge -p '{"metadata":{"finalizers":null}}'
done
helm uninstall argocd -n argocd
kubectl delete ns argocd

# 2. Traefik first, while LBC is still running to remove the load balancer
kubectl delete ns traefik --wait=true --timeout=300s
aws elbv2 describe-load-balancers --region eu-west-2 --query 'LoadBalancers[].LoadBalancerName'
#    If the namespace hangs:
#    kubectl patch svc traefik -n traefik --type merge -p '{"metadata":{"finalizers":null}}'
#    aws elbv2 delete-load-balancer --region eu-west-2 --load-balancer-arn <arn>

# 3. The other app namespaces (this deletes the PVCs, so the CSI driver removes the volumes)
kubectl delete ns podinfo monitoring external-dns cert-manager --wait=true --timeout=300s

# 4. EBS volumes (any leftover shows as "available")
aws ec2 describe-volumes --region eu-west-2 \
  --filters Name=tag-key,Values=kubernetes.io/created-for/pvc/name \
  --query 'Volumes[].[VolumeId,State]' --output table
#    aws ec2 delete-volume --region eu-west-2 --volume-id <id>

# 5. Target groups, then k8s-* security groups (wait a minute or two after the load balancer is gone)
aws elbv2 describe-target-groups --region eu-west-2 --query 'TargetGroups[].TargetGroupArn' --output text
#    aws elbv2 delete-target-group --region eu-west-2 --target-group-arn <arn>
aws ec2 describe-security-groups --region eu-west-2 \
  --query 'SecurityGroups[?starts_with(GroupName,`k8s-`)].[GroupId,GroupName]' --output table
#    aws ec2 delete-security-group --region eu-west-2 --group-id <sg-id>

# 6. Detached network interfaces (only "available" ones; "in-use" belong to nodes, NAT or endpoints)
aws ec2 describe-network-interfaces --region eu-west-2 \
  --filters Name=vpc-id,Values=$VPC_ID Name=status,Values=available \
  --query 'NetworkInterfaces[].[NetworkInterfaceId,Description]' --output table
#    aws ec2 delete-network-interface --region eu-west-2 --network-interface-id <id>

# 7. DNS records: list, then delete the A and TXT ones in the console (leave NS and SOA)
aws route53 list-resource-record-sets --hosted-zone-id Z02290411JA35JCBMQUUJ \
  --query "ResourceRecordSets[?Type=='A' || Type=='TXT']"

# 8. Destroy
cd infra/env/prod && terragrunt run-all destroy