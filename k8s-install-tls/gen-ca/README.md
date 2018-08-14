## 生成证书

官方参考：https://kubernetes.io/docs/concepts/cluster-administration/certificates/

第一步： 生成根证书

第二部：由根证书颁发各个服务的使用到的证书

服务证书使用对应关系表：

| 服务                             | 证书                                       | 位于节点 |
| -------------------------------- | :----------------------------------------- | -------- |
| kube-apiserver                   | ca.pem、kubernetes.pem、kubernetes-key.pem | Master   |
| kube-scheduler                   |                                            | Master   |
| kube-controller-manager          | ca.pem、ca-key.pem                         | Master   |
| kubelet                          | ca.pem                                     | Node     |
| kube-proxy                       | ca.pem、kube-proxy.pem、kube-proxy-key.pem | Node     |
| kubectl                          | ca.pem、admin.pem、admin-key.pem           | Manager  |
| etcd、flannel 服务不采用证书部署 |                                            |          |

### 下载证书工具


```bash
cd /usr/local/bin/
wget https://pkg.cfssl.org/R1.2/cfssl_linux-amd64 -O ./cfssl
wget https://pkg.cfssl.org/R1.2/cfssljson_linux-amd64 -O ./cfssljson
wget https://pkg.cfssl.org/R1.2/cfssl-certinfo_linux-amd64 -O ./cfssl-certinfo
chmod +x ./cf·ssl*
```

### 创建CA、根证书

创建CA证书配置文件 ca-config.json  、ca-csr.json 

```bash
# ca-config.json
cd ~/k8s-install-tls/gen-ca/ca-conf/
cat ca-config.json 
{
    "signing": {
        "default": {
            "expiry": "87600h"
        },
        "profiles": {
            "kubernetes": {
                "expiry": "87600h",
                "usages": [
                    "signing",
                    "key encipherment",
                    "server auth",
                    "client auth"
                ]
            }
        }
    }
}
```

```bash
# ca-csr.json
cd ~/k8s/k8s-install-tls/gen-ca/ca-conf/
cat ca-csr.json
{
    "CN": "kubernetes",
    "key": {
        "algo": "rsa",
        "size": 2048
    },
    "names": [
        {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing",
            "O": "k8s",
            "OU": "System"
        }
    ]
}
```

> CN： 可以看做是用户名、User Name
>
> O： 用户所属的组 Group
>
> User 、Group 将会被作为RBAC的授权标识

生成CA证书和私钥

```bash
cfssl gencert -initca ca-csr.json | cfssljson -bare ca
```

### kubernetes证书

```bash
root@k8s01:/k8s-install-tls/gen-ca/ssl-conf# cfssl gencert -ca=./ca.pem -ca-key=./ca-key.pem -config=./ca-config.json -profile=kubernetes ./kubernetes-csr.json | cfssljson -bare kubernetes
2018/06/15 15:42:51 [INFO] generate received request
2018/06/15 15:42:51 [INFO] received CSR
2018/06/15 15:42:51 [INFO] generating key: rsa-4096
2018/06/15 15:42:59 [INFO] encoded CSR
2018/06/15 15:42:59 [INFO] signed certificate with serial number 511064954877940838098909237068310625027718122795
2018/06/15 15:42:59 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
```

### kuber-proxy 证书

```bash
root@k8s01:/k8s-install-tls/gen-ca/ssl-conf# cfssl gencert -ca=./ca.pem -ca-key=./ca-key.pem -config=./ca-config.json -profile=kubernetes ./kube-proxy-csr.json | cfssljson -bare kube-proxy
2018/06/15 15:50:13 [INFO] generate received request
2018/06/15 15:50:13 [INFO] received CSR
2018/06/15 15:50:13 [INFO] generating key: rsa-4096
2018/06/15 15:50:23 [INFO] encoded CSR
2018/06/15 15:50:23 [INFO] signed certificate with serial number 439818088453367013715031387250535834446574166159
2018/06/15 15:50:23 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").

```

### metrics-server 证书

```bash
root@k8s01:/etc/kubernetes/ssl# cfssl gencert -ca=./ca.pem  -ca-key=./ca-key.pem -config=./ca-config.json  -profile=kubernetes  metrics-server-csr.json | cfssljson  -bare metrics-server
2018/06/22 14:31:31 [INFO] generate received request
2018/06/22 14:31:31 [INFO] received CSR
2018/06/22 14:31:31 [INFO] generating key: rsa-2048
2018/06/22 14:31:33 [INFO] encoded CSR
2018/06/22 14:31:33 [INFO] signed certificate with serial number 637479601437315879178405979638122928357885786516
2018/06/22 14:31:33 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
```



### Admin 证书

```bash
root@k8s01:/k8s-install-tls/gen-ca/ssl-conf# cfssl gencert -ca=./ca.pem -ca-key=./ca-key.pem -config=./ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
2018/06/21 17:08:53 [INFO] generate received request
2018/06/21 17:08:53 [INFO] received CSR
2018/06/21 17:08:53 [INFO] generating key: rsa-2048
2018/06/21 17:08:54 [INFO] encoded CSR
2018/06/21 17:08:54 [INFO] signed certificate with serial number 534091525587758072784575750985426836880405389670
2018/06/21 17:08:54 [WARNING] This certificate lacks a "hosts" field. This makes it unsuitable for
websites. For more information see the Baseline Requirements for the Issuance and Management
of Publicly-Trusted Certificates, v.1.1.6, from the CA/Browser Forum (https://cabforum.org);
specifically, section 10.2.3 ("Information Requirements").
```

###注解

ca-config.json 是CA证书的配置文件、定义根证书、CA的使用场景(profile)，和具体参数

| 证书请求文件        | CN                | O              |
| ------------------- | ----------------- | -------------- |
| ca-csr.json         | kubernetes        | k8s            |
| admin-csr.json      | admin             | system:masters |
| kubernetes-csr.json | kubernetes        | k8s            |
| kube-proxy-csr.json | system:kube-proxy | k8s            |
|                     |                   |                |

> 证书请求文件在[ssl-conf](https://github.com/lijiapengsa/k8s/tree/master/k8s-install-tls/gen-ca/ssl-conf) 目录



