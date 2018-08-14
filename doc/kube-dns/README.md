## kube-dns

### 1. 部署 kube-dns

下载配置kube-dns描述文件：

```bash
# 原版描述文件
wget https://storage.googleapis.com/kubernetes-the-hard-way/kube-dns.yaml
# 实际使用(更改后)描述文件
https://github.com/lijiapengsa/kubernetes/blob/master/doc/kube-dns/kube-dns.yaml
```

> 不管使用以上哪个 kube-dns 的描述文件后都需要根据实际环境需要修改三个地方：
>
> * clusterIP： 修改为前面教程预留的IP地址、10.211.200.2
> * kube-dns启动参数： 在Deployment配置块中 args: 处添加kube-master-url 配置、--kube-master-url=http://192.168.10.249:8080、如果不配置默认会使用https方式连接master
> * kube-dns启动image：为了能够快速启动将所有默认google官方的image替换为国内阿里云的

准备-上传配置描述文件

```bash
# 修改服务器 resolv.conf 文件、添加search 和 nameserver
https://github.com/lijiapengsa/kubernetes/blob/master/doc/kube-dns/resolv.conf
# 上传配置配置文件、
cd k8s/Doc
ansible-playbook -i ./hosts  playbook.yaml
```

> resolv.conf 最后一行中的地址替换为真实环境的 kube-dns 地址

描述文件准备好后，可以开始创建

```bash
# 登陆到master服务器上创建(之所以不用playbook是为了熟悉dashboard的安装过程)
root@k8s01:/apps/k8s/dashboard# kubectl apply -f ./kubernetes-dashboard.yaml
secret "kubernetes-dashboard-certs" created
serviceaccount "kubernetes-dashboard" created
role.rbac.authorization.k8s.io "kubernetes-dashboard-minimal" created
rolebinding.rbac.authorization.k8s.io "kubernetes-dashboard-minimal" created
deployment.apps "kubernetes-dashboard" created
```

```bash
# 创建成功后(等待10s-20s)
root@k8s01:/apps/k8s/dashboard# kubectl  -n kube-system get all
NAME                           READY     STATUS    RESTARTS   AGE
pod/kube-dns-5c68b47b5-gjgs9   3/3       Running   0          20m

NAME               TYPE        CLUSTER-IP     EXTERNAL-IP   PORT(S)         AGE
service/kube-dns   ClusterIP   10.211.200.2   <none>        53/UDP,53/TCP   20m

NAME                       DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/kube-dns   1         1         1            1           20m

NAME                                 DESIRED   CURRENT   READY     AGE
replicaset.apps/kube-dns-5c68b47b5   1         1         1         20m
```

> 可以看到 pod 的状态已经全部为READY、CLUSTER-IP 为手动指定IP地址

### 2. 测试 kube-dns

```bash
# 测试用到的描述文件地址(不用改任何东西)
https://github.com/lijiapengsa/kubernetes/blob/master/doc/kube-dns/busybox.yaml
```

```bash
# 创建测试用到的资源
root@k8s01:/apps/k8s/qa# kubectl create -f busybox.yaml
root@k8s01:/apps/k8s/qa# kubectl exec -ti busybox -- nslookup  www.baidu.com
Server:    10.211.200.2
Address 1: 10.211.200.2 kube-dns.kube-system.svc.cluster.local

Name:      www.baidu.com
Address 1: 103.235.46.39
root@k8s01:/apps/k8s/qa#
root@k8s01:/apps/k8s/qa# kubectl exec -ti busybox -- nslookup kubernetes.default
Server:    10.211.200.2
Address 1: 10.211.200.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes.default
Address 1: 10.211.0.1 kubernetes.default.svc.cluster.loca
```

> 解释：以上可以看到 kube-dns service （10.211.200.2） 可以成功的将domain解析为 Address

kube-dns在将来可能会被coredns替代

------

有证书和无证书的的方式仅仅在于无证书的需要手动指定kube-master的非加密端口