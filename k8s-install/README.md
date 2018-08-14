 #### 1.环境准备

  服务器规划:

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

#### 2.下载准备

kubernetes下载地址: https://github.com/kubernetes/kubernetes/releases

因为是到https://dl.k8s.io 这个站点下载，比较慢。所以建议在中控机上预先执行下载的任务。然后将可执行程序上传至服务器。节省下载时间。

```bash
download -> kubernetes.tar.gz
tar zxf kubernetes.tar.gz
cd kubernetes
cluster/get-kube-binaries.sh 
```
> 需要等待10~30min左右（看网速），下载完成后
>
> 在~/kubernetes/client/bin目录有Node节点程序 kubectl
>
> 在~/kubernetes/server目录有Master节点程序压缩包 kubernetes-server-linux-amd64.tar.gz，解压得到Master节点执行程序

也可以直接下载server tar包：[CHANGELOG 页面](https://github.com/kubernetes/kubernetes/blob/master/CHANGELOG.md)、server 的tar包已经包含client、所以不用单独下载client 包。

```bash
root@k8s01:/usr/local/src/kubernetes/server#cd /usr/local/src/kubernetes/server
root@k8s01:/usr/local/src/kubernetes/server#tar zxf kubernetes-server-linux-amd64.tar.gz
root@k8s01:/usr/local/src/kubernetes/server# ls 
kubernetes  kubernetes-manifests.tar.gz  kubernetes-server-linux-amd64.tar.gz  README
root@k8s01:/usr/local/src/kubernetes/server# ls -lh  kubernetes/server/bin/
total 2.0G
-rwxr-xr-x 1 root root  56M Apr 27 18:14 apiextensions-apiserver
-rwxr-xr-x 1 root root 126M Apr 27 18:14 cloud-controller-manager
-rw-r--r-- 1 root root    8 Apr 27 18:14 cloud-controller-manager.docker_tag
-rw-r--r-- 1 root root 128M Apr 27 18:14 cloud-controller-manager.tar
-rwxr-xr-x 1 root root 255M Apr 27 18:14 hyperkube
-rwxr-xr-x 1 root root 150M Apr 27 18:14 kubeadm
-rwxr-xr-x 1 root root  55M Apr 27 18:14 kube-aggregator
-rw-r--r-- 1 root root    8 Apr 27 18:14 kube-aggregator.docker_tag
-rw-r--r-- 1 root root  56M Apr 27 18:14 kube-aggregator.tar
-rwxr-xr-x 1 root root 214M Apr 27 18:14 kube-apiserver
-rw-r--r-- 1 root root    8 Apr 27 18:14 kube-apiserver.docker_tag
-rw-r--r-- 1 root root 215M Apr 27 18:14 kube-apiserver.tar
-rwxr-xr-x 1 root root 140M Apr 27 18:14 kube-controller-manager
-rw-r--r-- 1 root root    8 Apr 27 18:14 kube-controller-manager.docker_tag
-rw-r--r-- 1 root root 142M Apr 27 18:14 kube-controller-manager.tar
-rwxr-xr-x 1 root root  52M Apr 27 18:15 kubectl
-rwxr-xr-x 1 root root 146M Apr 27 18:14 kubelet
-rwxr-xr-x 1 root root  49M Apr 27 18:14 kube-proxy
-rw-r--r-- 1 root root    8 Apr 27 18:14 kube-proxy.docker_tag
-rw-r--r-- 1 root root  95M Apr 27 18:14 kube-proxy.tar
-rwxr-xr-x 1 root root  47M Apr 27 18:14 kube-scheduler
-rw-r--r-- 1 root root    8 Apr 27 18:14 kube-scheduler.docker_tag
-rw-r--r-- 1 root root  49M Apr 27 18:14 kube-scheduler.tar
-rwxr-xr-x 1 root root 2.1M Apr 27 18:14 mounter
```

> 以上ls 所见就是部署master和node节点所用到的所有组件

#### 3.部署准备

下载ansible-playbook代码：git@github.com:lijiapengsa/k8s.git

```bash
git clone git@github.com:lijiapengsa/k8s.git
cd k8s/k8s-install/file/
mv ~/client ./ # 将下载准备步骤中的结果的server和client目录移动到此目录
mv ~/server ./
tree . -L 4  # 最终结构如下
.
├── client
│   ├── README
│   ├── bin -> /usr/local/src/kubernetes/platforms/linux/amd64
│   ├── kubectl  # kube客户端工具
│   └── kubernetes-client-linux-amd64.tar.gz
└── server
    ├── README
    ├── kubernetes
    │   ├── LICENSES
    │   ├── addons
    │   ├── kubernetes-src.tar.gz
    │   └── server
    │       └── bin # k8s所有的二进制可执行程序的文件夹，playbook从这里copy
    ├── kubernetes-manifests.tar.gz
    └── kubernetes-server-linux-amd64.tar.gz

```
playbook结构分析：

```bash
pwd
~/k8s/k8s-install
tree . -L 2
.
├── README.md
├── config # 放所有配置文件的地方
│   ├── config
│   ├── kube-apiserver
│   ├── kube-apiserver.service
│   ├── kube-controller-manager
│   ├── kube-controller-manager.service
│   ├── kube-proxy
│   ├── kube-proxy.service
│   ├── kube-scheduler
│   ├── kube-scheduler.service
│   ├── kubelet
│   ├── kubelet.kubeconfig
│   └── kubelet.service
├── file # “部署准备”步骤中产生的二进制执行文件目录
│   ├── client
│   └── server
├── hosts # 服务器信息
└── playbook.yml # playbook剧本

4 directories, 15 files
```



#### 4.部署Master节点和Node节点

* 需要自定义的地方	

  * ~/k8s/k8s-install/hosts

    ```ba
    [k8s-node] 下写入所有的Node IP地址
    [k8s-master] 下写入Master的 IP地址
    ```

  * ~/k8s/k8s-install/config/config

    ```bash
    #修改KUBE_MASTER变量值为实际Master节点IP地址
    KUBE_MASTER="--master=http://192.168.10.249:8080"
    ```
  * ~/k8s/k8s-install/config/kubelet

      ```bash
      #修改CLUSTER_DNS变量为向ETCD中注册的IP地址段中的一个IP地址
      CLUSTER_DNS='--cluster-dns=10.211.200.2'
      ```

  * ~/k8s/k8s-install/config/kubelet.kubeconfig

      ```yaml
      #修改server参数值为实际api-server的IP地址
      server: http://192.168.10.249:8080
      ```

  * ~/k8s/k8s-install/config/kube-apiserver

      ```bash
      # KUBE_API_ADDRESS 设置为 0.0.0.0
      KUBE_API_ADDRESS="--insecure-bind-address=0.0.0.0"
      # KUBE_ETCD_SERVERS 设置为真实的IP地址
      KUBE_ETCD_SERVERS="--etcd-servers=http://192.168.10.247:2379,http://192.168.10.248:2379,http://192.168.10.249:2379"
      # KUBE_SERVICE_ADDRESSES 设置为Flannel中在etcd注册的地址段
      KUBE_SERVICE_ADDRESSES="--service-cluster-ip-range=10.211.200.0/16"
      ```

* 执行部署

    其他没有明确指出的需要自定义的配置，尽量不要改动！

    ```bash
    cd ~/k8s/k8s-install/
    ansible-playbook -i ./hosts playbook.yml
    ➜  k8s-install git:(master) ✗ ansible-playbook -i ./hosts playbook.yml
    
    PLAY [k8s-node] *************************************************************** 
    
    GATHERING FACTS *************************************************************** 
    ok: [192.168.10.248]
    ok: [192.168.10.249]
    ok: [192.168.10.247]
    略....
    ```

* 检查部署结果

    在Master节点上执行以下命令查看已经部署结果

    ```bash
    root@k8s01:/usr/local/src/kubernetes# kubectl get cs
    NAME                 STATUS    MESSAGE              ERROR
    scheduler            Healthy   ok                   
    controller-manager   Healthy   ok                   
    etcd-0               Healthy   {"health": "true"}   
    etcd-2               Healthy   {"health": "true"}   
    etcd-1               Healthy   {"health": "true"} 
    ```

    查看注册的Node节点：

    ```bash
    root@k8s01:~# kubectl  get node
    NAME      STATUS    ROLES     AGE       VERSION
    k8s01     Ready     <none>    14m       v1.10.2
    k8s02     Ready     <none>    15h       v1.10.2
    k8s03     Ready     <none>    14m       v1.10.2
    ```



> 部署工作完成（一切都只是刚刚开始...）







