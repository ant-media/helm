#!/bin/bash
#
# This script automatically installs Let's Encrypt certificate to your Ant Media Server Cluster.
#

namespace="antmedia"
ingress_controller_name="antmedia-ingress-nginx-controller"
get_ingress=`kubectl get -n $namespace svc $ingress_controller_name -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
declare -A hostname
check_edge=`kubectl get ingress ant-media-server-edge 2> /dev/null  | wc -l`

if [ "$check_edge" != "0" ]; then
	hostname[edge]=`kubectl get -n $namespace ingress ant-media-server-edge -o jsonpath='{.spec.rules[0].host}'`
	hostname[origin]=`kubectl get -n $namespace ingress ant-media-server-origin -o jsonpath='{.spec.rules[0].host}'`
else
	hostname[origin]=`kubectl get -n $namespace ingress ant-media-server-origin -o jsonpath='{.spec.rules[0].host}'`
fi

echo -e "\033[0;31mYou must have the kubectl tool installed and accessing the Kubernetes cluster.\033[0m"

# Check DNS record
if ! [ -x "$(which dig)" ]; then
	sudo apt-get install bind9-dnsutils -y -qq
fi

for hostnames in "${hostname[@]}"; do
	if [ `dig @8.8.8.8 $hostnames +noall +answer |wc -l` == "0" ]; then
		echo "Please make sure your DNS record is correct then run the script again later."
		exit 1
	elif [ `dig @8.8.8.8 $hostnames +short` != "$get_ingress" ]; then
		echo "Please make sure your DNS record is correct then run the script again later."
		exit 1
	fi
done

# Install cert-manager
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set installCRDs=true
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml

kubectl create -f - <<EOF
---
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - http01:
          ingress:
            class: nginx
---
EOF

# Delete Self-Signed certificates
if [ "$check_edge" != "0" ]; then
    kubectl delete -n $namespace secret antmedia-cert-edge
    kubectl delete -n $namespace secret antmedia-cert-origin
else
	kubectl delete -n $namespace secret antmedia-cert-origin
fi

# Update annotates for Let's Encrypt
kubectl annotate -n $namespace ingress cert-manager.io/cluster-issuer=letsencrypt-production --all

sleep 10

echo "If "kubectl get certificates -n antmedia" command return TRUE, you can understand that your certificates were installed without any problems."

kubectl get cert



