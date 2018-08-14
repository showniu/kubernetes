# coredns

在kubernetes最新的版本中（v1.11.0）、官方正式将`coredns`加入kubernetes的附加选项（准确的说从v1.9版本开始`coredns`就成为了kubernetes的附加选项）、使用kubeadm安装方式d时默认的DNS服务由`kube-dns`变成`coredns`。相较于`kube-dns`、`coredns`组件更少、更灵活、上手更简单。更多的信息请参阅官方的[v1.11.0版本公告](https://kubernetes.io/blog/2018/06/27/kubernetes-1.11-release-announcement/)

## 部署coredns

下载coredns的描述文件。原版文件请参考 [链接直达](https://github.com/kubernetes/kubernetes/tree/master/cluster/addons)

```bash
# 这是经过修改的描述文件
https://github.com/lijiapengsa/kubernetes/blob/master/doc/coredns/coredns.yaml.base
```

> 修改说明：
>
> 61行、`__PILLAR__DNS__DOMAIN__` 修改为 `cluster.local`
>
> 109行、修改为国内镜像
>
> 172行、`clusterIP` 指定为之前为DNS服务预留的IP地址

执行部署

```bash
kubectl create -f coredns.yaml.base
```

## 测试coredns

这个测试和kube-dns基本一样、关于dns测试更多详细内容参考[官网文档](https://kubernetes.io/docs/tasks/administer-cluster/dns-debugging-resolution/)

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

------

kubernetes 的服务发现就是基于DNS服务、关于服务发现的更多内容~~~慢慢慢慢研究