# Horizontal Pod Autoscaler 水平自动伸缩

HPA全称 Horizontal Pod Autoscaler、可以根据观察到的CPU使用率自动调整`replication controller`、`deploymont`、`replica set`（或者自定义指标），HPA不适用于无法缩放的对象、如`Deamonset`。

 ![HPA如何工作](http://github-images.test.upcdn.net/github.io/HPA.png)

HPA实现了一个控制循环，这个循环周期是由控制管理器的`--horizontal-pod-autoscaler-sync-period`标志控制（默认30秒），在每一个循环周期内控制管理器根据`HorizontalPodAutoscaler`定义中的指定的度量标准查询资源利用率。控制管理器从metrics API（指定的POD的资源指标）或者自定义的metrics API（所有其他指标）获取指标。

* 对于Pod的资源指标（CPU），控制器从`HorizontalPodAutoscaler`针对的每个Pod的metrics API获取资源指标。然后，如果配置了目标利用率值、控制器将以每个Pod容器上的等效资源请求的百分比来计算利用率值。如果设置了目标原始值，则直接使用原始度量值。然后控制器从所有的目标Pod中获取录用率的平均值或者原始值。并用于产生缩放所需的副本的数量的比率。

但是如果、Pod本身没有资源的方面的任何配置（资源限制），就没有办法获取到Pod的资源使用率。并且`autoscaler`不会采取任何操作。

* 对于每个Pod的自定义指标、控制器的功能类似于每个Pod的资源指标。不同的是它适用于原始值、而不是使用率值
* 对于对象度量、提取单个度量、并与目标值进行比较。产生上面所说的比率。

所描述的`HorizontalPodAutoscaler`通常从一系列的聚合API（aggregated APIs）中提取指标(`metrics.k8s.io`,`custom.metrics.k8s.io`,  `external.metrics.k8s.io`)。`metrics.k8s.io`API通常由metrics-server提供、需要单独提供。关于metrics-server更多信息可以参阅<a href="../metrics-server/README.md">本文连接</a>、[官方连接](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#how-does-the-horizontal-pod-autoscaler-work)。`HorizontalPodAutoscaler`也可以直接从Heapster获取指标，但是从Kubernetes1.11开始Heapster就开始被弃用。

## API 对象

Horizontal Pod Autoscaler 是kubernetes `autoscaling`API组中的一个API资源、目前稳定版本只支持根据CPU自动缩放，可以在`autoscaling/v1`API版本中找到。

beat版本开始支持内存、定制度量的扩展，可以在`autoscaling/v2beta`API版本中找到

使用`autoscale/v1`版本时、`autoscale/v2beta`中的新字段被保留为注释。

## 支持kubectl 进行Horizontal Pod Autoscaler

和所有的API资源一样、HPA支持通过kubectl管理。可以通过`kubectl create`命令创建一个新的`autoscalers`(自动缩放器)，可以通过`kubectl get hpa`命令获取所有的自动缩放器，并通过`kubectl describe hps`命令获取更详细的描述。然后也可以通过`kubectl delete hpa`删除自动缩放器。

还可以通过`kubectl autoscale`这个特殊的命令、直接创建一个Horizontal Pod Autoscaler。例如：`kubectl autoscale rs foo --mix=1 --max=5 --cpu-percent=80`命令、为复制集foo创建了一个自动缩放器、目标使用率设置为80%、副本数量介于1-5之间

## 滚动更新中的Autoscaling

目前在Kubernetes中、可以通过关管理replication controller、和使用deployment来执行[滚动更新](https://kubernetes.io/docs/tasks/run-application/rolling-update-replication-controller/)，但是HPA仅仅支持deployment这一中方法、HPA绑定到deployment对象、它负责deployment对象的大小、deployment负责设置复制集replica sets的大小

HPA不能直接操作复制控制器replication controller执行滚动更新，就是说HPA不能和复制控制器replication controller进行绑定和滚动更新（例如使用`kubectl rolling-update`）。原因是当滚动更新创建新的复制控制器replication controller时、HPA不会绑定到新创建的复制控制器。

## 支持冷却/延迟

当在使用HPA管理一组副本时、由于所评估的度量的动态性质、副本的数量会不断的波动。这个有时候被称为颠簸（referred to as thrashing 原话是这样的）。

从v1.6开始、集群管理员可以通过调整`kube-controller-manager`组件的HPA全局配置选项来缓解这个问题：

* --horizontal-pod-autoscaler-downscaler-delay

  看名字就看猜的出来干嘛用的了、这个配置项的的值是一个持续的时间、意思是指定自动缩放器在完成当前任务后等待多长时间以后才能执行另一个缩减的动作。默认值是5分钟（5m0s）

* --hotizontal-pod-autoscaler-upscaler-dealy

  和上面一样的作用、这个是指定自动缩放器在完成当前任务后等待多久才能执行另一个扩容（启动）的动作。默认是3分钟（3m0s）

> 官网有这样一个提示：
>
> 集群管理原应该非常了解调整这些参数的后果、如果延迟时间设置的时间太长、就会出现HPA无法及时相应工作负载的变化，但是如果如果设置又很短、同样也会出现“颠簸”的现象（嗯...等于没设）

## 支持多指标

Kubernetes1.6 增加了基于多个指标扩展的支持，可以使用`autoscaling/v2beta1`的API版本，为HPA指定多个指标进行缩放。然后HPA会评估每个指标、并根据该指标产生一个新的比例，用最大的比例作为新的比例标准

## 支持自定义指标

Kubernetes1.6 增加了在HPA中使用自定义指标的功能、可以通过`autoscaling/v2beta1`API在HPA中添加自定义指标、然后Kubernetes会查询自定义指标的API、以获取自定义指标的值。

## 支持Metrics API

默认情况系、HPA控制器会自动在“一系列”的APIs中获取指标，为了能够放问这些（一系列）指标、集群管理员必须做到以下几点：

* API汇聚层（API aggregation layer）已经启用、开启[连接](https://kubernetes.io/docs/tasks/access-kubernetes-api/configure-aggregation-layer/)
* 对应的API已经注册（不明所以）
  * 资源指标（CPU/内存...）、`metrics.k8s.io`API、这是由<a href="../metrics-server/README.md">metrics-server</a>提供，作为集群的插件addon启用。
  * 自定义指标、`custom.metrics.k8s.io`API、It’s provided by “adapter” API servers provided by metrics solution vendors. Check with your metrics pipeline, or the [list of known solutions](https://github.com/kubernetes/metrics/blob/master/IMPLEMENTATIONS.md#custom-metrics-api). If you would like to write your own, check out the [boilerplate](https://github.com/kubernetes-incubator/custom-metrics-apiserver) to get started.
  * 外部指标、`external.metrics.k8s.io`、可以由上面的自定义指标适配器提供
* 默认`horizontal-pod-autoscaler-use-rest-clients`为True或者未设置、将这个配置设置为false会其切换到基于heapster的自动缩放、不推荐这样使用（heapster已经弃用）

## [What's next](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#what-s-next)

- Design documentation: [Horizontal Pod Autoscaling](https://git.k8s.io/community/contributors/design-proposals/autoscaling/horizontal-pod-autoscaler.md).
- kubectl autoscale command: [kubectl autoscale](https://kubernetes.io/docs/reference/generated/kubectl/kubectl-commands/#autoscale).
- Usage example of [Horizontal Pod Autoscaler](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/).

翻译和整理自[官方文档](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/)

