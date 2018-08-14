# k8s部署实践

### 基本步骤流程：

* 部署etcd
* 部署flannel
* 部署Kubernetes集群（带证书和不带证书）
  * 生成证书
  * 部署Master节点
  * 部署Node节点
* 部署kube-dns服务
* 部署dashboard
* 部署helm
* 部署promethus
* 部署ingress
  * nginx 
  * traefik
* 部署应用
  * 
* ...(未完待续)

#### 原理和操作文档请参考`/doc`目录下内容，和各目录下README.md

------

会部署只是k8s知识的皮毛、请不要止步于此。仔细研究各个组件的基本原理、这样才会更上一层楼。

------

kubernetes集群之上的各种基础服务的描述文件都在源码里面点击[链接直达](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)

------

官方文档：https://kubernetes.io/docs/tasks/tools/install-kubectl/

官方中文：https://kubernetes.io/cn/docs/concepts/cluster-administration/certificates/

Dashboard官方部署文档：https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

中文翻译：http://docs.kubernetes.org.cn/

个人教程：https://github.com/sadlar/k8s-install-note

个人教程：https://github.com/gjmzj/kubeasz

