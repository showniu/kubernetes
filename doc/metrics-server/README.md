## metrices-server

kubernetes metrics server 作为Heapster的继承者，在整个集范围内通过kubelet公开的`kubernetes.summary_api`的数据来收集各个计算节点和POD的CPU、内存使用情况。`summary_api`是一个效率高的API，用于将kubelet、cadviso的数据传递到metrics server。metrices-server 是一个轻量级的短期内存存储。

## cadvisor

cadvisor是一个开源的容器使用资源和性能分析代理，专为容器生、本身支持Docker容器。在kubernetes中cadvisor被集成到kubelet的二进制文件中（也就是说不用单独部署），cadvisor会自动发现该节点上的所有容器，并收集CPU、内存、文件系统和网络使用情况统计信息。还可以通过分析节点上的“root”容器来收集节点整体使用情况。

## kubelet

kubelet作为kubernetes集群中master节点和node节点之间通信的桥梁。它管理运行在该节点上的Pod和容器。kubelet将每个pod转换组成容器、并从cadvisor获取单个容器的使用情况的信息统计。然后通过REST API 公开汇总的Pod资源的使用统计信息。

受heapster项目的启发、比heapster的优势在于：不在需要通过apiserver代理、提供认证和授权、一部分组件也对此依赖（HPA、scheduler、kubectl top）。

[原文链接](https://kubernetes.io/docs/tasks/debug-application-cluster/resource-usage-monitoring/)

## 通过helm部署metrics-server

```bash
helm fetch stable/metrics-server
tar zxf metrics-server-1.1.0.tgz
cd metrics-server/
helm install . --name metrics-server
```

> values.yaml 文件改动：
>
> * 21行、更换为国内仓库
> * 26行、添加summary_api地址

## 检查部署结果

部署成功后并不能马上就能有结果。需要等待30s以左右、就可以通过以下方式查询：

方式一：

```bash
kubectl get --raw "/apis/metrics.k8s.io/v1beta1/nodes"
```

方式二：

```bash
kubectl  top nodes
NAME      CPU(cores)   CPU%      MEMORY(bytes)   MEMORY%
k8s01     244m         12%       2596Mi          44%
k8s02     166m         8%        1640Mi          27%
k8s03     116m         5%        1511Mi          25%
```

方式三：

```bash
kubectl  top pod --all-namespaces
NAME                                             CPU(cores)   MEMORY(bytes)
metrics-server-654dc478f-sc9jq                   1m           14Mi
nginx-ingress-controller-5cff54b969-vmlqp        3m           121Mi
...
```

官方文档太xx简单了、有问题的话、在项目的issue看看

额外参考https://github.com/stefanprodan/k8s-prom-hpa

