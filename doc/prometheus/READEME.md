## 通过helm部署 promethues

### 部署prometheus

```bash
cd kubernetes/doc/prometheus
helm install --name monitor \
--namespace monitoring \
-f prom-settings.yaml \
-f prom-alertsmanager.yaml \
-f prom-alertrules.yaml \
prometheus

```

### 部署grafana

```bash
cd kubernetes/doc/grafana/
helm install \
--name grafana \
--namespace monitoring \
-f grafana-settings.yaml \
-f grafana-dashboards.yaml \
grafana
```

### 修改配置文件（升级）

```bash
helm upgrade monitor -f xxx -f xxx ... prometheus
helm upgrade grafana -f xxx -f xxx ... prometheus
```

### 删除

```bash
helm delete prometheus  --purge
helm delete grafana  --purge
```

###使用

prometheus-server  http://node_ip:30002

prometheus-alertmanager  http://node_ip:30003

Grafana http://node_ip:30004



参考连接 https://github.com/helm/charts/tree/master/stable/prometheus