## metrics-server

kubernetes metrics server 作为Heapster的继承者，在整个集范围内通过`kubernetes.summary_api`的数据来收集各个计算节点和POD的CPU、内存使用情况。`summary_api`是一个效率高的API，用于将kubelet、cadviso的数据传递到metrics server。metrices-server 是一个轻量级的短期内存存储。

cadvisor是一个开源的容器使用资源和性能分析代理，专为容器生、本身支持Docker容器。在kubernetes中cadvisor被集成到kubelet的二进制文件中（也就是说不用单独部署），cadvisor会自动发现该节点上的所有容器，并收集CPU、内存、文件系统和网络使用情况统计信息。还可以通过分析节点上的“root”容器来收集节点整体使用情况。

kubelet作为kubernetes集群中master节点和node节点之间通信的桥梁。它管理运行在该节点上的Pod和容器。kubelet将每个pod转换组成容器、并从cadvisor获取单个容器的使用情况的信息统计。然后通过REST API 公开汇总的Pod资源的使用统计信息。

[原文链接](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)









参考

https://github.com/stefanprodan/k8s-prom-hpa

https://k8s-install.opsnull.com/09-4.metrics-server%E6%8F%92%E4%BB%B6.html

生成证书:

```bash
cfssl gencert -ca=./ca.pem  -ca-key=./ca-key.pem -config=./ca-config.json  -profile=kubernetes  metrics-server-csr.json | cfssljson  -bare metrics-server
```

```bash

kubectl get --raw "/apis/metrics.k8s.io/v1beta1"

```

未完待续...

