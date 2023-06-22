# Monitoring AMS with Grafana

In this deployment, Kafka, Logstash, Elasticsearch, and Grafana are installed.

Original Document Page: https://antmedia.io/docs/guides/advanced-usage/monitoring/monitoring-ams-with-grafana/

# Installing the Chart

```
helm repo add antmedia https://ant-media.github.io/helm
helm repo update
helm install monitoring antmedia/monitoring
```