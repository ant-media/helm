# Ant Media Server 

Ant Media Server Helm chart for Kubernetes

## Introduction
Ant Media Server installs the following
- Edge/Origin pods
- MongoDB pod
- Ingress controller

## Prerequisites
- Kubernetes >= 1.23
- Helm v3
- cert-manager

## Installing the Chart
Add the AMS repository to Helm:
```shell script
helm repo add antmedia https://ant-media.github.io/helm
helm repo update
helm install antmedia antmedia/antmedia --set origin={origin}.{example.com} --set edge={edge}.{example.com} --set licenseKey="YOUR_LICENSE_KEY" --namespace antmedia --create-namespace
```

## Installing SSL 
By default, a self-singed certificate comes in the Ant Media Server Kubernetes structure that you install with Helm. If you want, you can replace it with your own certificate as below or follow the steps below for Let's Encrypt.

```sh
kubectl create -n antmedia secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE} 
```

#### Update DNS Records

Run `kubectl get ingress -n antmedia` command to get your Ingress IP address and then update your DNS according to the ingress IP address and hostnames.

You can do a DNS query as follows.
```sh
dig origin.antmedia.cloud +noall +answer
dig edge.antmedia.cloud +noall +answer
```
Example output:

```sh
root@murat:~# dig edge.antmedia.cloud +noall +answer
edge.antmedia.cloud.	300	IN	A	x.x.x.x
```
If the result of this output is your Ingress IP address, your DNS has been updated so you can access via HTTPS (self-signed) or HTTP.

#### Let's Encrypt 

If you want, you can do this with the script we have prepared or manually by following the steps below.

##### Installation with script

```sh
wget https://raw.githubusercontent.com/ant-media/helm/add_helm_repo/ams-k8s-ssl.sh

bash ams-k8s-ssl.sh
```

Then wait for the certificate to be created.

If everything went well, the output of the `kubectl get -n antmedia certificate` command will show the value `True` as follows.
```
NAME                   READY   SECRET                 AGE
antmedia-cert-origin   True    antmedia-cert-origin   21m
```
##### Manual installation

[Click here](https://resources.antmedia.io/docs/install-ssl-on-kubernetes-using-lets-encrypt) for step-by-step installation.

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
| `licenseKey`                                      | License key                                                                                            | `{}`                                                                     |
| `autoscalingOrigin.targetCPUUtilizationPercentage`                            | Target CPU utilization percentage for autoscaler for Origin                                                                          | `60`                                                                               |
| `autoscalingOrigin.minReplicas`                                 | Minimum number of deployment replicas for the compute container.                                                                                | `1`                                                                               |
| `autoscalingOrigin.maxReplicas`                                  | Maximum number of deployment replicas for the compute container.                                    | `10`                                                                               |
| `autoscalingEdge.targetCPUUtilizationPercentage`                                 | Target CPU utilization percentage for autoscaler for Edge                         | `60`                                                                                |
| `autoscalingEdge.minReplicas`                          | Minimum number of deployment replicas for the compute container.     | `1`                                                                               |
| `autoscalingEdge.maxReplicas`                               | Maximum number of deployment replicas for the compute container.                                                         | `10`                                                                               |



## Example Usage
```
helm install antmedia antmedia/antmedia --set origin=origin.antmedia.io --set edge=edge.antmedia.io --set autoscalingEdge.targetCPUUtilizationPercentage=20 --set autoscalingEdge.minReplicas=2 --namespace antmedia --create-namespace

```


