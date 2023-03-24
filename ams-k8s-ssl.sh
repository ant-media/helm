#!/bin/bash
#
# This script automatically installs Let's Encrypt certificate to your Ant Media Server Cluster.
# If you use different namespace or deployment/ingress etc. names, you must make the changes manually.
#

namespace="antmedia"
ingress_controller_name="antmedia-ingress-nginx-controller"
get_ingress=`kubectl get -n $namespace svc $ingress_controller_name -o jsonpath='{.status.loadBalancer.ingress[0].ip}'`
origin_ssl="kubectl get certificate antmedia-cert-origin -o jsonpath='{.status.conditions[].status}' -n $namespace --ignore-not-found=true"
edge_ssl="kubectl get certificate antmedia-cert-edge -o jsonpath='{.status.conditions[].status}' -n $namespace --ignore-not-found=true"

check() {
  OUT=$?
  if [ $OUT -ne 0 ]; then
    echo "There is a problem with installing the cert-manager. Please check the output.log file to debug it."
    exit $OUT
  fi
}

cert_manager() {
  log_file="output.log"
  helm repo add jetstack https://charts.jetstack.io &> $log_file
  check
  helm repo update &> $log_file
  check
  helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set installCRDs=true &> $log_file
  check
  kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml &> $log_file
  check
}

declare -A hostname
check_edge=`kubectl get -n $namespace ingress ant-media-server-edge 2> /dev/null  | wc -l`

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
cert_manager

# Create letsencrypt-production ClusterIssuer
kubectl create -f - &> /dev/null <<EOF 
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
    kubectl delete -n $namespace secret antmedia-cert-edge --ignore-not-found=true
    kubectl delete -n $namespace secret antmedia-cert-origin --ignore-not-found=true
    echo "Self-Signed certificates have been deleted."
else
	kubectl delete -n $namespace secret antmedia-cert-origin --ignore-not-found=true
	echo "The self-Signed certificate has been deleted."
fi

# Update annotates for Let's Encrypt
kubectl annotate -n $namespace ingress cert-manager.io/cluster-issuer=letsencrypt-production --all 

# Wait for verifying.
sleep 10

if [ "$check_edge" != "0" ]; then
    if [ $(eval $edge_ssl) == "True" ]; then
    	echo "Edge certificate installed."
    else
    	echo "Edge certificate is not installed. Run this command for debugging: kubectl describe cert ant-media-server-edge -n $namespace"
    fi
fi

if [ $(eval $origin_ssl) == "True" ]; then
	echo "Origin certificate installed."
else
	echo "Origin certificate is not installed. Run this command for debugging: kubectl describe cert ant-media-server-origin -n $namespace"
fi
