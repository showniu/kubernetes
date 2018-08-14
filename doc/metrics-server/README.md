## metrics-server

参考

https://github.com/stefanprodan/k8s-prom-hpa

https://k8s-install.opsnull.com/09-4.metrics-server%E6%8F%92%E4%BB%B6.html

生成证书:

```bash
cfssl gencert -ca=./ca.pem  -ca-key=./ca-key.pem -config=./ca-config.json  -profile=kubernetes  metrics-server-csr.json | cfssljson  -bare metrics-server
```

```bash

kubectl get --raw "/apis/metrics.k8s.io/v1beta1"


```

未完待续...

