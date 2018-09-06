## 通过helm部署 promethues

### 为什么要使用prometheus

在前面<a href="../metrics-server/README.md">metrics-service</a>已经可以根据计算节点、Pod的使用率进行HPA。但是是没有办法做到自定义指标的，这个自定义指标不是CPU、内存、磁盘的自定义。而是基于kubernetes集群的应用程序的指标的自定义，要收集应用程序级别的指标，就需要prometheus来配合。

相较于metrics-server、prometheus是一个更完整的监控管道（Full Metrics Pipelines）。

prometheus可以原生的检测kubernetes、node、和prometheus本身。prometheus operator简化了prometheus在kubernetes上的安装，并且允许使用prometheus adapter自定义 metrics API。prometheus本身支持查询语法和简单的内置仪表板，用于插件和可视化数据。此外也可以使用grafana展示数据。

[原文链接](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/#full-metrics-pipelines)

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

### 使用

prometheus-server  http://node_ip:30002

prometheus-alertmanager  http://node_ip:30003

Grafana http://node_ip:30004

参考连接 https://github.com/helm/charts/tree/master/stable/prometheus