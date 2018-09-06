Kubernetes权限控制

引用自官方图表

![](http://github-images.test.upcdn.net/github.io/access-control-overview.svg)

kubernetes集群的权限控制主要就是对APIserver的权限控制、入上图所示基本上依次需要以下三个步骤：

* 认证 Authentication

  * <a href="../../k8s-install-tls/gen-ca/README.md">证书</a>

    通过服务的启动参数`--client_ca_file=xxx`、这个参数所引用的client证书，验证被通过时、那么这个验证记录中的主体对象将会作为请求的username。

  * token

    smlqbz

  * 基本信息

    用户名密码（还未尝试）

* 授权 Authorization

  * ~~ABAC 已弃用~~
  * <a href="./RBAC.md">RBAC</a>

* <a href="./UsingAdmissionControllers.md">准入控制 Admission Controll</a>

  有很多、作为kube-apiserver服务的启动参数

[参考连接](https://kubernetes.io/cn/docs/admin/accessing-the-api/)

