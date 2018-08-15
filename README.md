# kubernetes实践

### 基本步骤流程：

- [x] <a href="etcd/README.md">etcd</a>
- [x] <a href="flannel/README.md">flannel</a>
- [x] Kubernetes集群
  - [x] <a herf="k8s-install-tls/gen-ca/README.md">生成证书</a>
  - [x] <a herf="k8s-install-tls/README.md">部署Master节点</a>
  - [x] <a herf="k8s-install-tls/README.md">部署Node节点</a>
- [x] <a herf="doc/kube-dns/README.md">kube-dns</a>
- [x] <a herf="doc/dashboard/README.md">dashboard</a>
- [ ] <a herf="doc/metrics-server/README.md">metrics-server</a>
- [x] <a herf="doc/helm/README.md">helm</a>
- [x] <a herf="doc/promethus/README.md">promethus</a>
  - [x] <a herf="doc/promethus/README.md">grafana</a>
- [x] ingress
  - [x] <a herf="doc/ingress/README.md">nginx</a>
  - [ ] treafik
- [ ] 未完待续



#### 各组件原理和操作文档请参考`/doc`目录下内容，和各目录下README.md

------

会部署只是k8s知识的皮毛、也不要止步于此。仔细研究各个组件的基本原理、这样才会更上一层楼。

------

kubernetes集群之上的各种基础服务的描述文件都在源码里面点击[链接直达](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)

------

官方文档：https://kubernetes.io/docs/tasks/tools/install-kubectl/

官方中文：https://kubernetes.io/cn/docs/concepts/cluster-administration/certificates/

Dashboard官方部署文档：https://kubernetes.io/docs/tasks/access-application-cluster/web-ui-dashboard/

中文翻译：http://docs.kubernetes.org.cn/

个人教程：https://github.com/sadlar/k8s-install-note

个人教程：https://github.com/gjmzj/kubeasz


