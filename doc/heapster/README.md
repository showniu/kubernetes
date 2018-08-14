## Heapster

* 上篇"[k8s05-部署dashboard展板](https://lijiapengsa.github.io/2018/06/13/k8s05-%E9%83%A8%E7%BD%B2dashboard%E5%B1%95%E6%9D%BF/)"初步部署了dashboard，但是不能展示 Pod、Nodes 的 CPU、内存等 metric 图形，本篇将部署heapster插件用来获取和展示相关资源的指标图形。

* 这个组件被Kubernetes放弃了[链接](https://github.com/kubernetes/heapster/blob/master/docs/deprecation.md)。

* 官方推荐的这个替代服务[metrics server](https://github.com/kubernetes-incubator/metrics-server)

![image-20180614103020052](http://github-images.test.upcdn.net/github.io/image-20180614103020052.png)
