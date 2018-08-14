# dashboard

## 1. 无证书部署 dashboard

### 执行部署

下载配置 dashboard 描述文件：

```bash
# 原版描述文件
https://raw.githubusercontent.com/kubernetes/dashboard/master/src/deploy/recommended/kubernetes-dashboard.yaml
# 实际使用(更改后)描述文件
https://github.com/lijiapengsa/k8s/tree/master/Doc/dashboard/kubernetes-dashboard.yaml
```

> 修改说明：不管使用以上哪个 kube-dashboard 的描述文件后都需要根据实际环境需要修改三个地方：
>
> * dashboard启动参数：Deployment 配置块 args：处添加 --apiserver-host=http://192.168.10.249:8080
> * 启动image：将google 的image 替换为阿里云的 registry.cn-beijing.aliyuncs.com/k8s_images/kubernetes-dashboard-amd64:v1.8.3
> * 端口暴露：service配置块添加NodePort暴露方式(可参考[Kubernetes内部服务如何被外部访问](http://lijiapeng.ga/2018/05/14/Kubernetes%E5%86%85%E9%83%A8%E6%9C%8D%E5%8A%A1%E5%A6%82%E4%BD%95%E8%A2%AB%E5%A4%96%E9%83%A8%E8%AE%BF%E9%97%AE/#more)）

```bash
# 创建
root@k8s01:/apps/k8s/dashboard# kubectl  create  -f kubernetes-dashboard.yaml
secret "kubernetes-dashboard-certs" created
serviceaccount "kubernetes-dashboard" created
role.rbac.authorization.k8s.io "kubernetes-dashboard-minimal" created
rolebinding.rbac.authorization.k8s.io "kubernetes-dashboard-minimal" created
deployment.apps "kubernetes-dashboard" created
```

```bash
# 等待10s-20s
root@k8s01:/apps/k8s/dashboard# kubectl get svc --namespace=kube-system
NAME                   TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)         AGE
kube-dns               ClusterIP   10.211.200.2    <none>        53/UDP,53/TCP   36m
kubernetes-dashboard   NodePort    10.211.32.240   <none>        443:32149/TCP   4s
root@k8s01:/apps/k8s/dashboard# kubectl get pods --namespace=kube-system
NAME                                    READY     STATUS    RESTARTS   AGE
kube-dns-5c68b47b5-gjgs9                3/3       Running   0          37m
kubernetes-dashboard-57ccc88449-jnmkh   1/1       Running   0          40s
```

> 解释： 以上结果说明 dashboard 的 pod 和service 都已经被创建，且都是READY状态

###  访问测试

#### 先获取access_token：

```bash
kubectl  -n kube-system describe secret $(kubectl -n kube-system get secret | grep dashboard |grep token | awk '{print $1}')
```

![image-20180613185353699](http://github-images.test.upcdn.net/github.io/image-20180613185353699.png)

#### 通过NodePort方式访问

* 查看pod被部署到那个Node

  ```bash
  root@k8s01:~# kubectl  -n kube-system describe $(kubectl  -n kube-system get all |  grep dashboard |  grep pod |  awk '{print $1}') |  grep Node

  Node:           k8s03/192.168.10.247
  Node-Selectors:  <none>
  ```

  > 可以看到部署在k8s03节点 192.168.10.247上

* 访问 （只限NodePort方式部署可用）

  必须使用https方式访问

  ex： https://192.168.10.247:30001 （30001是我在描述文件里面定义的）

#### 登陆

<__> 选择令牌-输入令牌-登陆-登陆后就是以下界面：

![image-20180611182825620](http://github-images.test.upcdn.net/github.io/image-20180611182825620.png)

dashboard部署初步完成



## 3. 基于有证书集群部署dashboard

> 集群有证书和无证书的部署方式的区别仅仅是：无证书方式需要手动指定kube-apiserver的非tls地址、也就是`- --apiserver-host=http://192.168.10.249:8080` 这个参数

### 执行部署

下载`dashboard`描述文件`kubernetes-dashboard-tls.yaml`

```bash
# 我实际使用的描述文件
https://github.com/lijiapengsa/k8s/blob/master/Doc/dashboard/kubernetes-dashboard-tls.yaml
```

> 修改说明：
>
> * 94行-108行、是配置dashboard控制台可以跳过验证的配置。后面会提到
> * 132行、将默认`k8s.grc.io`的镜像替换为国内镜像
> * 178行、新增`type: NodePort`参数、添加NodePort的暴露方式
> * 182行、新增`nodePort: 30001`参数、指定NodePort暴露的具体端口
> * 基本不用再改任何东西了、除非你很熟悉、很熟悉。

```bash
# 将描述文件上传至服务器执行部署
root@k8s01:/apps/k8s/dashboard# kubectl  create  -f kubernetes-dashboard-tls.yaml
```

### 访问测试

访问集群内任意节点的`30001`端口、即可访问到`dashboard login`界面、http://x.x.x.x:30001

#### token方式login

```bash
root@k8s01:~# kubectl create serviceaccount k8s-admin -n kube-system
root@k8s01:~# kubectl create clusterrolebinding dashboard-admin --serviceaccount=kube-system:k8s-admin --clusterrole=cluster-admin
root@k8s01:~# kubectl -n kube-system get secret
root@k8s01:~# kubectl -n kube-system describe secret k8s-admin-token-d8dlb
```

![](http://github-images.test.upcdn.net/github.io/gen-dashboard-access-token.png)

复制该str到控制台填入即可登陆

参考：https://github.com/kubernetes/dashboard/wiki/Creating-sample-user

#### kubeconfig 方式login

暂无

#### 通过跳过的方式login

在dashboard描述文件中添加一下内容：

```yaml
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kubernetes-dashboard-admin
  namespace: kube-system
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: kubernetes-dashboard
  namespace: kube-system
```

>  创建一个ClusterRoleBinding，允许cluster-admin访问kubernetes-dashboard服务（ServiceAccount）、RBAC知识可参考github的 `doc/权限控制/RBAC.md` 或者blog的`kubernetes的权限RBAC控制机制`

参考文档：https://github.com/kubernetes/dashboard/wiki/Access-control#basic