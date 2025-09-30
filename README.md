# README

#### About
# Metrics Exporter for Dell PowerStore

This exporter collects metrics from multiple PowerStore systems using PowerStore's RESTful API. It supports Prometheus or Zabbix for data collection and Grafana for data visualization. This exporter has been tested with PowerStore REST API versions 1.0, 2.0, 3.5, 4.0; Zabbix version 6.0LTS, Prometheus version 3.3.1, and Grafana version 11.6.5.

#### Build
This project is to be built using a Go environment.

```
cd powerstore-metrics-exporter
sudo go build -o ./build/powerstore-metrics-exporter
```
#### Run
The exporter config file is ./config.yml and can be changed to point to another port other than the default of 9010. It is strongly recommended to create an operator user role in PowerStore, then update the storeageList section with the IP address and username/password details of the PowerStore(s).

```
./build/powerstore-metrics-exporter -c config.yml
```
### TLS
To enable HTTPS access, you need to modify three options `exporter.https.enable`, `exporter.https.crtPath`, and `exporter.https.keyPath` in the `config.yml` file. You may need to generate your own enterprise certificate.
### Using Bulk api
To enable Bulk api request, you need to configure the three options `storageList.bulkCollector`, `exporter.bulkDir`, and `exporter.bulkCron` in the config.yml file.
The utilization of the PowerStore Manager's bulk API allows for a significant enhancement in the collection speed of all performance metrics. It is required, however, that the user account for PowerStore Manager possesses a minimum permission level of "Storage Operator" (operator role not working) in order to enable this functionality.

### Docker Image
Build the docker image first.
```
sudo go build -o ./build/powerstore-metrics-exporter
sudo docker build -t powrstore-exporter-image .
```
Start the container.
For example:
```
sudo docker run -d \
  --name powerstore-exporter \
  -p 9010:9010 \
  -v /home/pst_exporter/config.yml:/powerstore_exporter/config.yml \
  -v /home/pst_exporter/https/:/powerstore_exporter/https/ \
  -v /home/pst_exporter/bulk/:/powerstore_exporter/bulk/ \
  powrstore-exporter-image:latest
```

#### Collect
base path: http://{#Exporter IP}:{#Exporter Port}/metrics

```
Cluster              /{#PowerStoreIP}/cluster
Appliance            /{#PowerStoreIP}/appliance
Capacity             /{#PowerStoreIP}/capacity
Hardware             /{#PowerStoreIP}/hardware
Volume               /{#PowerStoreIP}/volume
VolumeGroup          /{#PowerStoreIP}/volumeGroup
Port                 /{#PowerStoreIP}/port
Nas                  /{#PowerStoreIP}/nas
FileSystem           /{#PowerStoreIP}/file
```
Sample: http://127.0.0.1:9010/metrics/10.0.0.1/cluster

You can choose either Prometheus or Zabbix to collect/scrape metrics, then use Grafana to render/visualize the metrics.
For Prometheus the flow would be: PowerStore(s) --> exporter --> multiple targets --> Prometheus scrape jobs --> Prometheus --> Grafana
For Zabbix the flow would be: PowerStore(s) --> exporter --> multiple targets --> [ Create PowerStore host in Zabbix --> Link this host with PowerStore Zabbix template --> Scrape targets by Zabbix http client --> Zabbix DB --> Zabbix API] --> Grafana


#### Prometheus + Grafana

Add ./templates/prometheus/prometheus.yml to all jobs in your Prometheus .yml config file, then restart your Prometheus instance or reload. You can update scrape interval time to support your application monitoring requirements. We use Grafana to render metrics collected by Prometheus.

#### Zabbix and Grafana
When you create a host in Zabbix, use ./templates/zabbix/zbx_exporter_tempaltes.yaml to link PowerStore(s) to the Zabbix host. We use Grafana to render metrics collected by Zabbix. You can also create dashboards in Zabbix directly.

