## helm

### 安装

部署很简单将二进制执行程序放在PATH的路径下面即可、helm的[下载连接](https://github.com/helm/helm/releases)

如下helm安装正常：

```
root@k8s01:~# helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
```

### 集群授权

因为集群使用了RBAC所以在使用前需要配置权限、权限描述文件`rbac-config.yaml`

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: tiller
  namespace: kube-system
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: tiller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
  - kind: ServiceAccount
    name: tiller
    namespace: kube-system
```

> 这是集群管理员的权限

```bash
root@k8s01:/apps/k8s/helm# kubectl  create  -f  rbac-config.yaml
serviceaccount/tiller created
```

### 初始化helm工具

```bash
root@k8s01:/apps/k8s/helm# helm init --service-account tiller
Creating /root/.helm
Creating /root/.helm/repository
Creating /root/.helm/repository/cache
Creating /root/.helm/repository/local
Creating /root/.helm/plugins
Creating /root/.helm/starters
Creating /root/.helm/cache/archive
Creating /root/.helm/repository/repositories.yaml
Adding stable repo with URL: https://kubernetes-charts.storage.googleapis.com
Adding local repo with URL: http://127.0.0.1:8879/charts
$HELM_HOME has been configured at /root/.helm.

Tiller (the Helm server-side component) has been installed into your Kubernetes Cluster.

Please note: by default, Tiller is deployed with an insecure 'allow unauthenticated users' policy.
For more information on securing your installation see: https://docs.helm.sh/using_helm/#securing-your-helm-installation
Happy Helming!
root@k8s01:/apps/k8s/helm#
root@k8s01:/apps/k8s/helm# helm list 
```

> 授权和启动tiller服务，`helm list` 命令无错误输出即权限配置正确，服务启动成功

helm安装成后，就可以借helm 安装其它服务、这个实践中`grafana`、`monitor`、`nginx-ingress` 服务是通过helm 的方式部署的。

### helm默认配置无法下载的问题

默认情况下、helm默认会使用`https://kubernetes-charts.storage.googleapis.com/`作为stable repository的地址、所以国内用户会无法正常使用这个。

```bash
root@k8s01:~# helm repo list
NAME  	URL
stable	https://kubernetes-charts.storage.googleapis.com
local 	http://127.0.0.1:8879/charts
```

不过阿里云的容器服务也提供了这个的镜像站点https://kubernetes.oss-cn-hangzhou.aliyuncs.com/charts(...好像阿里云的很久没有更新了)。

这个人自己自己镜像了一个，测试的目的凑合这用吧https://burdenbear.github.io/kube-charts-mirror/ 。后期可以自己单独管理一个helm仓库。

```bash
root@k8s01:~# helm repo remove stable
root@k8s01:~# helm repo add stable https://burdenbear.github.io/kube-charts-mirror
root@k8s01:~# helm update
root@k8s01:~# helm repo list
NAME  	URL
local 	http://127.0.0.1:8879/charts
stable	https://burdenbear.github.io/kube-charts-mirror/
```

### 异常处理

```bash
root@k8s01:~# helm version
Client: &version.Version{SemVer:"v2.9.1", GitCommit:"20adb27c7c5868466912eebdf6664e7390ebe710", GitTreeState:"clean"}
E0717 17:13:09.953791   19899 portforward.go:331] an error occurred forwarding 43082 -> 44134: error forwarding port 44134 to pod 535eccc638f97ae50ee67f868996ecdc7213bfa58a8761f81beb6f60a2112182, uid : unable to do port forwarding: socat not found.
Error: cannot connect to Tiller
root@k8s01:~# 
```

在每一个node上面安装socat 

```bash
apt-get install socat
```
------

https://hub.kubeapps.com/ 、helm的仓库、相当于docker的hub。

helm文档官方翻译版：https://whmzsu.github.io/helm-doc-zh-cn/

