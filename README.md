# Ant Media Server 

Ant Media Server Helm chart for Kubernetes

## Introduction
Ant Media Server installs the following
- Edge/Origin pods
- MongoDB 
- Ingress

## Prerequisites
- Kubernetes >= 1.23
- Helm v3
- cert-manager

## Installing the Chart
Add the AMS repository to Helm:
```shell script
helm repo add antmedia https://ant-media.github.io/helm
helm repo update
helm install antmedia antmedia/antmedia --set origin={origin}.{example.com} --set edge={edge}.{example.com} --namespace antmedia
```

## Installing SSL 
By default, a self-singed certificate comes in the Ant Media Server Kubernetes structure that you install with Helm. If you want, you can replace it with your own certificate as below or follow the steps below for Let's Encrypt.

```sh
kubectl create -n antmedia secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE} 
```

#### Let's Encrypt 

After installation run the below command to get Ingress IP address.
```sh
kubectl get ingress -n antmedia
```

Example Output:

```
NAME                      CLASS    HOSTS                   ADDRESS        PORTS     AGE
ant-media-server-origin   <none>   origin.antmedia.cloud   162.19.225.6   80, 443   9m59s
```
#### Update the DNS record according to the HOSTS and ADDRESS values.

You can do DNS query as follows.
```sh
dig origin.antmedia.cloud +noall +answer
```
#### Now let's move on to Let's Encrypt installation.
```sh
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --version v1.9.1 --set installCRDs=true
kubectl apply -f https://github.com/jetstack/cert-manager/releases/download/v1.9.1/cert-manager.crds.yaml
```
Create a YAML file in your working directory and name it **ams-k8s-issuer-production.yaml** Add the following content (Do not forget to change the email address.)
```
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-production
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: change_me
    privateKeySecretRef:
      name: letsencrypt-production
    solvers:
      - http01:
          ingress:
            class: nginx
```
```sh
kubectl create -f ams-production-issuer.yaml
```
When you run the `kubectl get clusterissuers` command, you will see an output like the one below.
```
letsencrypt-production   True    1m
```
We use the **antmedia-cert-edge** and **ant-media-cert-origin** secrets by default for the Origin and Edge sides, and we delete them because there is a self-signed serial on them.
```sh
kubectl delete -n antmedia secret antmedia-cert-edge 
kubectl delete -n antmedia secret antmedia-cert-origin
```
We should edit or recreate our Ingresses.
```sh
kubectl edit -n antmedia ingress ant-media-server-origin
```
You must add an annotation **cert-manager.io/cluster-issuer: letsencrypt-production** in the ingress configuration with the issuer or cluster issuer name.

Example:
```
metadata:
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-production
    kubernetes.io/ingress.class: nginx
    meta.helm.sh/release-name: antmedia
    meta.helm.sh/release-namespace: default
```
Then wait for the certificate to be created.

If everything went well, the output of the `kubectl get -n antmedia certificate` command will show the value `True` as follows.
```
NAME                   READY   SECRET                 AGE
antmedia-cert-origin   True    antmedia-cert-origin   21m
```

## Upgrade
The old installation must be uninstalled completely before installing the new version.

## Uninstalling the Chart
```sh
helm delete antmedia -n antmedia
```

## Parameters

| Parameter                               | Description                                                                                              | Default                                                                            |
|------------------------------------------------| -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `image`                                        | image repository                                                                                         | `antmedia/enterprise:latest` |
| `origin`                                       | Domain name of Origin server                                                                             | `{}`                                                                        |
| `edge`                                         | Domain name of Edge server                                                                               | `{}`                                                                     |
| `hostNetwork`                                  | If `false`, use turn server                                                                              | `true`                                                                            |
| `mongodb`                                      | MongoDB host                                                                                             | `mongo`                                                                     |
| `autoscalingOrigin.targetCPUUtilizationPercentage`                            | Target CPU utilization percentage for autoscaler for Origin                                                                          | `60`                                                                               |
| `autoscalingOrigin.minReplicas`                                 | Minimum number of deployment replicas for the compute container.                                                                                | `1`                                                                               |
| `autoscalingOrigin.maxReplicas`                                  | Maximum number of deployment replicas for the compute container.                                    | `10`                                                                               |
| `autoscalingEdge.targetCPUUtilizationPercentage`                                 | Target CPU utilization percentage for autoscaler for Edge                         | `60`                                                                                |
| `autoscalingEdge.minReplicas`                          | Minimum number of deployment replicas for the compute container.     | `1`                                                                               |
| `autoscalingEdge.maxReplicas`                               | Maximum number of deployment replicas for the compute container.                                                         | `10`                                                                               |



## Example Usage
```
helm install antmedia antmedia/antmedia --set origin=origin.antmedia.io --set edge=edge.antmedia.io --set autoscalingEdge.targetCPUUtilizationPercentage=20 --set autoscalingEdge.minReplicas=2 --namespace antmedia

```


