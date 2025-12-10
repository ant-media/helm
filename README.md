![workflow](https://github.com/ant-media/helm/actions/workflows/release.yml/badge.svg)
![GitHub release (latest by date)](https://img.shields.io/github/v/release/ant-media/helm)
  <a href="https://hub.docker.com/repository/docker/antmedia/enterprise" alt="Docker pulls">
    <img src="https://img.shields.io/docker/pulls/antmedia/enterprise" /></a>

## 🚀 Kubernetes-Ready Video Streaming

The **Ant Media Server Helm chart** simplifies deployment on Kubernetes, enabling auto-scaling, redundancy, and edge-origin streaming for robust, global video delivery.

---

### 🔍 Features

- Fully supports **Kubernetes Edge/Origin architecture**
- **MongoDB integration** for stream data storage
- Configurable **Ingress controller** for secure access
- **Persistent storage** with PVCs
- **Load-balanced** streaming delivery
- **Quick deployment** and easy upgrades

## Introduction
Ant Media Server installs the following
- Edge/Origin pods
- MongoDB pod
- Ingress controller

## Prerequisites
- **Kubernetes >= 1.23** (You must have a Kubernetes cluster installed and be able to access it with kubectl.)
- **Helm v3** (https://helm.sh/docs/intro/install/)
- **cert-manager** (No need if you are using "ams-k8s-ssl.sh" script)

## Installing the Chart
Add the AMS repository to Helm:
```sh
helm repo add antmedia https://ant-media.github.io/helm
helm repo update
helm install antmedia antmedia/antmedia \
  --set origin={origin}.{example.com} \
  --set edge={edge}.{example.com} \
  --set licenseKey="YOUR_LICENSE_KEY" \
  --namespace antmedia --create-namespace
```

## Installing SSL 
By default, a self-signed certificate comes in the Ant Media Server Kubernetes structure that you install with Helm. 

#### Custom Certificate
you can replace it with your own certificate as below or follow the steps below for Let's Encrypt.

```sh
kubectl create -n antmedia secret tls ${CERT_NAME} --key ${KEY_FILE} --cert ${CERT_FILE} 
```
#### AWS Certificate Manager

If you want to use your certificate created in [AWS Certificate Manager](https://docs.aws.amazon.com/acm/latest/userguide/gs-acm-request-public.html), you must first install the [AWS Load Balancer Controller](https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html)

After the installation is complete, simply add the following parameters to the helm command.

```sh
--set provider.aws=true --set aws.ssl.arn="arn:aws:acm:eu-west-1:1111111:certificate/a8c1-4b84-8126d6d4a21b"
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
#### Screenshots
<image align="center"><img width="250" height="150" src="https://antmedia.io/wp-content/uploads/2023/02/helm-login.png">
<image align="center"><img width="250" height="150" src="https://antmedia.io/wp-content/uploads/2023/02/helm-dashboard.png">
<image align="center"><img width="250" height="150" src="https://antmedia.io/wp-content/uploads/2023/02/helm-publishing.png">

##### Manual installation

[Click here](https://resources.antmedia.io/docs/install-ssl-on-kubernetes-using-lets-encrypt) for step-by-step installation.

## Upgrade

As an example, we are updating to version 2.6.4. Don't forget to specify the version you want to install.

```
kubectl patch deployment ant-media-server-origin -p '{"spec":{"template":{"spec":{"containers":[{"name":"ant-media-server","image":"antmedia/enterprise:2.6.4"}]}}}}' -n antmedia
kubectl patch deployment ant-media-server-edge -p '{"spec":{"template":{"spec":{"containers":[{"name":"ant-media-server","image":"antmedia/enterprise:2.6.4"}]}}}}' -n antmedia
```
Delete the Ant Media Server pods and ensure they are started with the new image.

```
kubectl delete pods -l app=ant-media-origin -n antmedia
kubectl delete pods -l app=ant-media-edge -n antmedia
```

## Uninstalling the Chart
```sh
helm delete antmedia -n antmedia
```

## Parameters

| Parameter                               | Description                                                                                              | Default                                                                            |
|------------------------------------------------| -------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------- |
| `image.repository`                                        | image repository                                                                                         | `antmedia/enterprise` |
| `image.tag`                                        | image tag                                                                                         | `latest` |
| `origin`                                       | Domain name of Origin server                                                                             | `{}`                                                                        |
| `edge`                                         | Domain name of Edge server                                                                               | `{}`                                                                     |
| `hostNetwork`                                  | Use turn server if false. By default, true, which limits to one pod per node. When false, multiple pods can be run per node.                                                                             | `true`                                                                            |
| `mongoDB`                                      | MongoDB host                                                                                             | `mongo`                                                                     |
| `mongoDB.replicaSet`                                      | MongoDB ReplicaSet                                                                                             | `false`                                                                     |
| `mongoDB.external`                                      | Remote MongoDB address (should be used with mongoDB.connectionString)                                                                                            | `false`                                                                     |
| `mongoDB.connectionString`                                      | MongoDB connection string                                                                                          | `{}`                                                                     |
| `licenseKey`                                      | Single license key for both Origin and Edge  deployments                                                                                           | `{}`                                                                     |
| `originLicense.Key`                                      | License key of Origin deployment                                                                                           | `{}`                                                                     |
| `edgeLicense.Key`                                      | License key of Edge deployment                                                                                            | `{}`                                                                     |
| `autoscalingOrigin.targetCPUUtilizationPercentage`                            | Target CPU utilization percentage for autoscaler for Origin                                                                          | `60`                                                                               |
| `autoscalingOrigin.minReplicas`                                 | Minimum number of deployment replicas for the compute container.                                                                                | `1`                                                                               |
| `autoscalingOrigin.maxReplicas`                                  | Maximum number of deployment replicas for the compute container.                                    | `10`                                                                               |
| `autoscalingEdge.targetCPUUtilizationPercentage`                                 | Target CPU utilization percentage for autoscaler for Edge                         | `60`                                                                                |
| `autoscalingEdge.minReplicas`                          | Minimum number of deployment replicas for the compute container.     | `1`                                                                               |
| `autoscalingEdge.maxReplicas`                               | Maximum number of deployment replicas for the compute container.                                                         | `10`                                                                               |
| `MongoDBNodeSelector`                               | Node Affinity for MongoDB deployment (Default key: nodepool).                                                         | `{}`                                                                               |
| `EdgeNodeSelector`                               | Node Affinity for AMS Edge deployment (Default key: nodepool).                                                         | `{}`                                                                               |
| `OriginNodeSelector`                               | Node Affinity for Edge Origin deployment (Default key: nodepool).                                                         | `{}`                                                                               |
| `kafkaURL`                               | The Kafka URL address to collect data.                                                         | `{}`                                                                               |
| `OriginCpu`                               | Set the CPU limit for Origin Pods.                                                         | `{}`                                                                               |
| `EdgeCpu`                               | Set the CPU limit for Edge Pods.                                                         | `{}`                                                                               |
| `UseGlobalIP`                               | Use global(Public) IP in network communication.                                                         | `true`                                                                               |
| `UseServerName`                               | Use Public IP as server name.                                                         | `true`                                                                               |
| `ReplaceCandidateAddress`                               | Replace candidate address with server name.                                                         | `true`                                                                               |
| `TurnStunServerURL`                               | TURN/STUN Server URL for the server side. It should start with "turn:URL:3478" or "stun:".                                                        | `{}`                                                                               |
| `TurnUsername`                               | TURN Server Usermame.                                                         | `{}`                                                                               |
| `TurnPassword`                               | TURN Server Password.                                                        | `{}`                                                                               |


## Turn Server Configuration

If `hostNetwork` is set to `false`, you will need a TURN server, and coturn will be automatically deployed. Example usage is as follows:

```
helm install antmedia antmedia/antmedia \
  --set origin={origin}.{example.com} \
  --set edge={edge}.{example.com} \
  --set licenseKey="YOUR_LICENSE_KEY" \
  --set hostNetwork=false \
  --set TurnUsername="YOUR_TURNSERVER_USERNAME" \
  --set TurnPassword="YOUR_TURNSERVER_PASSWORD" \
  --set TurnStunServerURL="turn:coturn" \
  --set UseGlobalIP=false \
  --set UseServerName=false \
  --namespace antmedia --create-namespace
```


## Example Usage
```
helm install antmedia antmedia/antmedia \
  --set origin=origin.antmedia.cloud \
  --set edge=edge.antmedia.io \
  --set autoscalingEdge.targetCPUUtilizationPercentage=20 \
  --set autoscalingEdge.minReplicas=2 \
  --namespace antmedia --create-namespace

```

## 📄 Resources

- **[Helm Chart Guide](https://antmedia.io/helm-chart-deployment-guide)**
- **[Cluster Architecture Diagram](https://antmedia.io/docs/cluster-architecture)**
- **[Ant Media Docs](https://docs.antmedia.io)**

---

## 💬 Need Help?

- **[Join the Community](https://github.com/ant-media/Ant-Media-Server/discussions)**
- **[Request a Demo](https://antmedia.io/request-a-demo)**
- **[Contact Us](http://antmedia.io)**
