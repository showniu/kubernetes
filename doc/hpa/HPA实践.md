# HPA实践

前面介绍了Horizontal Pod autoscaler（后面全部简称HPA） 的<a href="./README.md">工作原理</a>、和HPA的一些前提条件。并且也通过实践<a href="../metrics-server/README.md">metrics-server</a>、<a href="../prometheus/README.md">prometheus</a>满足了HPA的的前提必要条件。

下面就如何使用HPA这个特性、做一些实践工作。

## 运行一个php-apache服务

```bash
root@k8s01:~# kubectl run php-apache --image=registry.cn-beijing.aliyuncs.com/ioops/hpa-example --requests=cpu=200m --expose --port=80
service/php-apache created
deployment.apps/php-apache created
root@k8s01:/apps/k8s/ingress# kubectl get deployment php-apache
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
php-apache   1         1         1            1           1m
```

> 启动并没有那么快、拉镜像需要时间
>
> 原镜像是k8s.gcr.io/hpa-example、但是国内下载不到。所以我换成国内的。

## 创建一个Horizontal Pod Autoscaler

使用`kubectl autoscale`创建一个自动缩放器、这个缩放器控制上面创建的`php-apache`服务的副本在1-10个范围内。HPA会通过增加或者减少Pod的副本数（通过deploymen）、保持所有的Pod的CPU平均使用率维持在50%（前面我们设置了php-apache的CPU为200m、也就是说每个Pod的CPU使用率会维持在100m）

```bash
kubectl autoscale deployment php-apache --cpu-percent=50 --min=1 --max=10
```

创建成功后可以通过`kubectl get hpa`命令查看负载情况

```bash
root@k8s01:/apps/k8s/ingress# kubectl  get hpa
NAME         REFERENCE               TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   0%/50%    1         10        1          28s

```

## 增加压力

### 模拟负载方法一

集群内部模拟一个客户端向php-apache服务不断的发起请求

```bash
kubectl run -i --tty load-generator --image=busybox /bin/sh
Hit enter for command prompt
> while true; do wget -q -O- http://php-apache.default.svc.cluster.local; done
```

### 模拟负载方法二

再或者 通过ingress 入口将php-apache服务开放到集群外部、使用压测工具进行压测（必要前提：ingres已经部署完成）

ingress描述文件

```yaml
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: k8s-php-apache
  namespace: default
  annotations:
    kubernetes.io/ingress.class: "nginx"
spec:
  rules:
  - host: k8s-php.xingshulin.com
    http:
      paths:
      - backend:
          serviceName: php-apache
          servicePort: 80
```

> 将以上内容保存为k8s-php-apache.yaml 文件、使用`kubectl create -f k8s-php-apache.yaml`创建 

将添加到域名解析或者写入hosts文件、即可通过集群外部访问php-apache服务

```bash
ab -t 100000 -c  100  https://k8s-php.xingshulin.com/
```

> ab 压测工具、全名apachebench
>
> -n 请求总量
>
> -c 每次并发
>
> -t 设置请求时间、单位秒

### 查看负载和调度情况

在开一个终端、查看hpa的负载情况

```bash
root@k8s01:/apps/k8s/ingress# kubectl  get hpa
NAME         REFERENCE               TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
php-apache   Deployment/php-apache   165%/50%   1         10        4          6m
```

再查看deployment的情况

```shell
root@k8s01:/apps/k8s/ingress# kubectl get deployment php-apache
NAME         DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
php-apache   4         4         4            2           12m
```

>这时副本数量会出现变化

 **注意** 这个并不是实时的、因为在上个<a href="./README.md">文档</a>提到过、为了防止出现“颠簸”的情况、HPA有一个延迟的概念。如果没有出现预期的情况、请稍等几分钟。

## 缩减压力

停止对php-acha服务增加压力

```bash
> Control + C 停止
```

> 这时CPU使用率应该为0、副本为1
>
> **注意** 缩放副本依然需要几分钟

## 基于多指标和自定义指标的自动缩放功能

### 多指标

在使用`autoscaling/v2beta1`版本API部署可以自动缩放的php-apache服务时、可以引入添加其他指标。

第一步、获取`autoscaling/v2beta1`版本的HPA的YAMl格式额描述文件

```bash
root@k8s01:/apps/k8s/hpa# kubectl get hpa.v2beta1.autoscaling -o yaml > ./hpa-v2.yaml
root@k8s01:/apps/k8s/hpa# ls
hpa-v2.yaml
```

> 文件内targetCPUUtilizationPercetage这个配置字段已经被替换名为metrics的数组（不懂译过来的这句话、后面再回味一下）

CPU利用率是一种资源利用率指标resource metrics、因为他表示的是Pod容器上指定资源的百分比。**注意**你也可以指定CPU之外的其他指标。在默认情况下、唯一支持的其他的资源指标是内存。These resources do not change names from cluster to cluster, and should always be available（...这句话什么意思？没看懂😢），只要保证`metrics.k8s.io`API 是可用的。

你也可以为指定资源指标直接指定一个固定值、而不是请求值百分比。将`targetCPUUtilizationPercetage`配置段替换为`targetAverageValue`配置段即可。

### 自定义指标分类

还有两种其他类型的指标、这两种都被看做是自定义指标：

* pod metrics
* object metrics

这些指标可能在集群中有特定的名称、并且需要更高级的集群监控方面的配置

#### Pod metrics

这些备用的指标类型里第一种是Pod metrics、这些metrics描述了Pod、并且在Pod之间进行平均、并与目标值进行比较然后确定副本数量、它们工作的方式很像resource metrics（内置的CPU指标）。但是它们（Pod metrics）只有`targetAverageValue`字段。

Pod metrics 是由 metric 块定义的：

```yaml
type: Pods
pods:
  metricName: packets-per-second
  targetAverageValue: 1k
```

#### Object metrics

第二种metrics type 是 obeject metrics、这些指标描述了同一个namespace空间中的不同对象、而不是描述Pod的。**注意**metrics并不是从对象中获取的--它只是描述这个对象，object metrics不会有平均值、看起来是下面这样的：

```bash
type: Object
object:
  metricName: requests-per-second
  target:
    apiVersion: extensions/v1beta1
    kind: Ingress
    name: main-route
  targetValue: 2k
```

如果你想同时制定多个这样的metrics blocks的话、HPA会依次判断每个metric，HPA会计算每个metric指标所需要的副本数量、然后选择副本数最多的哪一个真正执行。

### 实例

例如、你的监控系统收集了网络流量相关的指标，可以使用`kubectl edit`命令更新HPA的定义：

```yaml
apiVersion: autoscaling/v2beta1
kind: HorizontalPodAutoscaler
metadata:
  name: php-apache
  namespace: default
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: php-apache
  minReplicas: 1
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      targetAverageUtilization: 50
  - type: Pods
    pods:
      metricName: packets-per-second
      targetAverageValue: 1k
  - type: Object
    object:
      metricName: requests-per-second
      target:
        apiVersion: extensions/v1beta1
        kind: Ingress
        name: main-route
      targetValue: 10k
...
```

> `-type:`指定了这个metric的类型、Resource指定了CPU的使用率要在50%、Pods指定了每秒处理1K个数据包、Object指定了ingress 入口后面的所有的Pod（包括要扩展的）每秒处理10K个请求。
>
> HPA会尝试满足上面的配置

### 基于非kubernetes对象的指标的自动缩放

**必要条件:** 集群版本必须是V1.10或更高（暂未实践）

在kubernetes运行的应用程序、也许需要基于和kubernetes集群内对象、没有明显关系的指标进行自动缩放（缘原句太长不好理解、人为加符号）例如描述和kubernetes的namespace命名空间没有关系的托管服务的指标。可以使用external metrics来解决

使用 external metrics 需要一定程度的监控系统方面的知识，并且需要有一个集群监控配置、类似于自定义指标所需要的集群监控配置（说的好像就是prometheus把?）。

使用external metrics、可以在HPA的描述文件中配置`metricName`字段、根据监控系统中的任意指标进行自动缩放。

此外、还可以使用`metricSelector`字段限制用于自动缩放的指标的时间序列，如果`metricsSelector`设置了多个序列、则HPA将取多个值的和

例如、应用程序处理来自来托管队列服务的任务、你可以添加以下部分到HPA的描述文件中、指定每30个任务需要一个工作者。

```yaml
- type: External
  external:
    metricName: queue_messages_ready
    metricSelector:
      matchLabels:
        queue: worker_tasks
    targetAverageValue: 30
```

如果在metric描述了可缩放的Pod中划分的工作或资源、则targetAverageValue字段描述了每个Pod可以处理的工作量。你可以使用targetValue定义外部指标的值、而不是会用targetAverageValue字段

## 本章小结：

内容有点多整理一下。HPA可以基于一下几个内容进行缩放功能：

1. resource metric （CPU）
2. multiple metric 多指标 （CPU和内存）、需要集群版本是V1.6或更高
3. Pod metric （Pod内部指标）
4. Object metric （kubernetes集群内其他对象、比如流量）
5. external  metric （外部指标）需要集群版本是V1.10或更高

