* 下载准备

   flannel下载地址：https://github.com/coreos/flannel/releases

   为节约下载时间，将执行程序预先下载到ansible中控服务器，然后分发给各个服务器

   ```bash
   ➜  git clone git@github.com:lijiapengsa/k8s.git
   ➜  cd k8s/flannel/file
   ➜  tar zxf flannel-v0.10.0-linux-amd64.tar.gz
   ➜  tree .
   .
   ├── config # 放配置文件的目录
   │   ├── docker.service ①
   │   ├── flanneld ②
   │   └── flanneld.service ③
   │   └── pre_deploy.sh ⑥
   ├── file # 放flannel解压后内容的目录
   │   ├── README.md
   │   ├── flannel-v0.10.0-linux-amd64.tar.gz
   │   ├── flanneld  ④
   │   └── mk-docker-opts.sh ⑤
   ├── hosts # 安装flannel的服务器,在这里添加你的主机
   └── playbook.yml # ansible 执行剧本文件
   2 directories, 10 files
   ```

     > ① docker的启动文件，docker根据flanneld.servic 启动Flannel后产生的环境变量"/run/flannel/docker文件内的变量"作为启动参数
     >
     >
     > ② Flannel启动需要的环境变量
     >
     > ③ Flannel服务的启动配置文件
     >
     > ④ 解压后的 flanneld 即执行程序
     >
     > ⑤ 脚本主要功能是生成一些变量，在 flanneld.service中被引用
     >
     > ⑥ Flannel启动前要向etcd内注册网络信息，此脚本实现该功能

* 执行剧本

   ```bash
   cd k8s/flannel
   ansible-playbook -i ./hosts playbook.yml
   ```
   ![k8s01-etcd-deploy](http://github-images.test.upcdn.net/github.io/k8s02-Flannel-deploy.png)

* 安装后检查

   ```bash
   root@k8s01:~# ifconfig
   docker0   Link encap:Ethernet  HWaddr 02:42:91:b5:2f:b3
             inet addr:10.211.92.1  Bcast:10.211.92.255  Mask:255.255.255.0
             UP BROADCAST MULTICAST  MTU:1500  Metric:1
             RX packets:13629 errors:0 dropped:0 overruns:0 frame:0
             TX packets:16166 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:0
             RX bytes:963089 (963.0 KB)  TX bytes:28703135 (28.7 MB)
   ...
   flannel.1 Link encap:Ethernet  HWaddr 2a:03:4f:85:8a:71
             inet addr:10.211.92.0  Bcast:0.0.0.0  Mask:255.255.255.255
             UP BROADCAST RUNNING MULTICAST  MTU:1450  Metric:1
             RX packets:24 errors:0 dropped:0 overruns:0 frame:0
             TX packets:28 errors:0 dropped:0 overruns:0 carrier:0
             collisions:0 txqueuelen:0
             RX bytes:2052 (2.0 KB)  TX bytes:2040 (2.0 KB)
   ...
   ```

   > IP 地址变化：docker0 IP 地址由默认172.17.0.1变成playbook.yml中配置etcd的网络中的一个具体IP地址
   >
   > 新增flannel1.1网卡：这个网卡是一个网段，由etcd中设置的网络划分出来的子网，没个node一个子网
   >
   > 所有被安装Flannel的服务器都应该出现上面两个变化，如果没有请针对该服务器单独在执行一边剧本

* 测试

     ```bash
     root@d8f8560559eb:/# traceroute 10.211.69.2
     traceroute to 10.211.69.2 (10.211.69.2), 30 hops max, 60 byte packets
      1  10.211.92.1 (10.211.92.1)  1.577 ms  1.462 ms  1.410 ms # 宿主机docker0IP地址
      2  10.211.69.0 (10.211.69.0)  1.364 ms  1.278 ms  1.228 ms # 对端宿主机flannel.1网络
      3  10.211.69.2 (10.211.69.2)  1.143 ms  1.071 ms  0.944 ms # 对端容器IP地址
     ```

     > 在安装Flannel的任意两台服务器上启动两个容器，就会获得etcd中注册的IP段内的IP地址，这些IP地址可以跨Node实现互相通信，即完成Flannel 的部署。
