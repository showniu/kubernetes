### k8s之使用Ansible-playbook快速启动ETCD集群

Github配置文件源码地址：

https://github.com/lijiapengsa/k8s/tree/master/etcd

源码功能分析：

```shell
➜  etcd git:(master) ✗ tree .
.
├── README.md
├── config	# etcd的配置（启动）文件目录
│   ├── etcd.service # etcd的启动文件
│   └── start.sh # etcd的启动脚本(暂时没用)
├── file # etcd 放执行程序的目录，没有的话请创建
├── hosts # 服务器地址
└── playbook.yml # ansible 剧本

2 directories, 5 files
```

部署步骤：

1. 下载ETCD执行程序到 k8s/file/  目录下

   ```bash
   ➜  k8s tree etcd/file
   etcd/file
   ├── etcd
   └── etcdctl

   0 directories, 2 files
   ```

2. 修改 k8s/etcd/hosts 文件

   ```bash
   ➜  k8s cat etcd/hosts
   [etcd] #这里和ansible的剧本文件playbook.yml中的"host: etcd" 对应
   192.168.10.247 ansible_hostname=k8s03 ansible_default_ipv4=192.168.10.247
   192.168.10.248 ansible_hostname=k8s02 ansible_default_ipv4=192.168.10.248
   192.168.10.249 ansible_hostname=k8s01 ansible_default_ipv4=192.168.10.249

   ```

3. 执行

   ```bash
   cd k8s/etcd
   ansible-playbook --private-key=/Users/ljp/.ssh/id_rsa -i ./hosts playbook.yml
   ```

   ![k8s01-etcd-deploy](http://github-images.test.upcdn.net/github.io/k8s01-etcd-deploy.png)

   建议配置服务器证书免密码认证

4. 安装后验证

   ![image-20180806160929739](http://github-images.test.upcdn.net/github.io/image-20180806160929739.png)
