# kubernetes tls 部署

## 1. 证书前提

部署前请确保此项目`k8s-install-tls`目录下`gen-ca/ssl`目录有以下结构和证书文件：

```bash
root@k8s01:/etc/kubernetes/ssl# ls -lh
total 44K
-rw-r--r-- 1 root root 1.7K Jul 11 16:56 admin-key.pem
-rw-r--r-- 1 root root 1.4K Jul 11 16:56 admin.pem
-rw-r--r-- 1 root root  384 Jul 11 15:08 ca-config.json
-rw-r--r-- 1 root root 1001 Jul 11 15:08 ca.csr
-rw-r--r-- 1 root root 1.7K Jul 11 15:08 ca-key.pem
-rw-r--r-- 1 root root 1.4K Jul 11 15:08 ca.pem
-rw-r--r-- 1 root root 3.2K Jul 11 16:36 kube-proxy-key.pem
-rw-r--r-- 1 root root 1.8K Jul 11 16:36 kube-proxy.pem
-rw-r--r-- 1 root root 3.2K Jul 11 16:36 kubernetes-key.pem
-rw-r--r-- 1 root root 2.0K Jul 11 16:36 kubernetes.pem
```

> 其中最为重要的pem证书文件，关于证书的如何制作生成、和证书详解请参考<a href="./gen-ca/README.md">文档</a>

## 2. 基础环境

kubernetes版本：1.11.0

服务器角色规划:

| 服务器IP/主机名/OS                       | 角色                  | 部署程序                                                     |
| ---------------------------------------- | --------------------- | ------------------------------------------------------------ |
| 192.168.10.249、k8s01、 Ubuntu16.04.3LTS | Master、etcd、Flannel | kubectl、kubelet、kube-apiserver、kube-controller-manager、kube-proxy、kube-scheduler、etcd、Flannel |
| 192.168.10.248、k8s02、Ubuntu16.04.3LTS  | Node、etcd、Flannel   | kubectl、kubelet、kube-proxy、etcd、flannel                  |
| 192.168.10.247、k8s03、Ubuntu16.04.3LTS  | Node、etcd、Flannel   | kubectl、kubelet、kube-proxy、etcd、flannel                  |

> 因资源有限使用3台节点部署所有服务
>
> Master节点有kube-apiserver、kube-controller-manager、kube-scheduler 三个主服务
>
> Node节点主要有kubelet、kube-proxy两个服务
>
> Flannel和etcd 部署在所有节点上

### Master节点部署

![](http://github-images.test.upcdn.net/github.io/k8s03-k8s-tls-deploy.png)

> 部署后kubelet 并不能马上加入Kubernetes集群，因为启用tls验证，所以需要到Master节点上授权允许Node节点加入集群。

### 配置kubectl 命令

master 节点部署后，kubectl 命令是不可用的，用以下命令生成kubectl 命令用到的kubeconfig文件

```bash
export KUBE_APISERVER="https://192.168.10.249:6443"
#
kubectl config set-cluster kubernetes \
--certificate-authority=/etc/kubernetes/ssl/ca.pem \
--embed-certs=true \
--server=${KUBE_APISERVER}

#
kubectl config set-credentials admin \
--client-certificate=/etc/kubernetes/ssl/admin.pem \
--client-key=/etc/kubernetes/ssl/admin-key.pem \
--embed-certs=true
#
kubectl config set-context kubernetes \
--cluster=kubernetes \
--user=admin
#
kubectl config use-context kubernetes

```

> 执行完成后、kebeconfig文件被保存为`~/.kube/config`文件，`~/.kube/config`对集群有最高权限。

kubectl命令配置完成后，可以查看k8s集群状态

```bash
root@k8s01:/etc/kubernetes/ssl# kubectl  get cs
NAME                 STATUS    MESSAGE              ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   {"health": "true"}
etcd-2               Healthy   {"health": "true"}
etcd-1               Healthy   {"health": "true"}
```

### Node节点部署

#### 手动授权：

```bash
# 查看请求
root@k8s01:~# kubectl  get csr
NAME                                                   AGE       REQUESTOR           CONDITION
node-csr-5vKIKToPaJS-Qf2a8w29GyM6AJedfgHCf8sqPVfTpv0   1m        kubelet-bootstrap   Pending
node-csr-DFPtGn1mDDruDzBt6DsI-lSipwphxN0Y_2TGr5bUhvU   1m        kubelet-bootstrap   Pending
node-csr-mwUWDqWtwd_IA2PSGTqw3TXsF7dwyz39QGVLdr0PwNs   1m        kubelet-bootstrap   Pending
# 批量通过授权
root@k8s01:~# kubectl  get csr |  tail -3 | awk '{print $1}'  | xargs kubectl  certificate approve
certificatesigningrequest.certificates.k8s.io "node-csr-5vKIKToPaJS-Qf2a8w29GyM6AJedfgHCf8sqPVfTpv0" approved
certificatesigningrequest.certificates.k8s.io "node-csr-DFPtGn1mDDruDzBt6DsI-lSipwphxN0Y_2TGr5bUhvU" approved
certificatesigningrequest.certificates.k8s.io "node-csr-mwUWDqWtwd_IA2PSGTqw3TXsF7dwyz39QGVLdr0PwNs" approved
```

#### 自动授权

有两种方式：

* 将 `~/.kube/config` 文件cp 到Node的 /etc/kubernetes/kubelet.kebeconfig 文件 node节点就会自动加入集群
* 也可以创建ClusterRoleBinding，用于自动批准证书：参考自[连接](https://github.com/opsnull/follow-me-install-kubernetes-cluster/blob/master/07-2.kubelet.md)

```bash
root@k8s01:/apps# cat csr-crb.yaml
# Approve all CSRs for the group "system:bootstrappers"
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: auto-approve-csrs-for-group
 subjects:
 - kind: Group
   name: system:kubelet-bootstrap # 注意这里的name是token.cvs文件的最后一列
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:nodeclient
   apiGroup: rbac.authorization.k8s.io
---
 # To let a node of the group "system:nodes" renew its own credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-client-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: system:certificates.k8s.io:certificatesigningrequests:selfnodeclient
   apiGroup: rbac.authorization.k8s.io
---
# A ClusterRole which instructs the CSR approver to approve a node requesting a
# serving cert matching its client cert.
kind: ClusterRole
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: approve-node-server-renewal-csr
rules:
- apiGroups: ["certificates.k8s.io"]
  resources: ["certificatesigningrequests/selfnodeserver"]
  verbs: ["create"]
---
 # To let a node of the group "system:nodes" renew its own server credentials
 kind: ClusterRoleBinding
 apiVersion: rbac.authorization.k8s.io/v1
 metadata:
   name: node-server-cert-renewal
 subjects:
 - kind: Group
   name: system:nodes
   apiGroup: rbac.authorization.k8s.io
 roleRef:
   kind: ClusterRole
   name: approve-node-server-renewal-csr
   apiGroup: rbac.authorization.k8s.io
```

> 这个文件是可以调优的，以后细看

执行该描述文件ClusterRoleBinding

```bash
root@k8s01:/apps# kubectl  apply -f csr-crb.yaml
clusterrolebinding.rbac.authorization.k8s.io/auto-approve-csrs-for-group created
clusterrolebinding.rbac.authorization.k8s.io/node-client-cert-renewal created
clusterrole.rbac.authorization.k8s.io/approve-node-server-renewal-csr created
clusterrolebinding.rbac.authorization.k8s.io/node-server-cert-renewal created
```

查看注册信息：

```bash
root@k8s01:/apps# kubectl  get node
NAME      STATUS    ROLES     AGE       VERSION
k8s01     Ready     <none>    20d       v1.11.0
k8s02     Ready     <none>    20d       v1.11.0
k8s03     Ready     <none>    20d       v1.11.0
```

至此集群部署完成

接下来继续部署<a href="../doc/coredns/README.md">coreDns</a> 服务