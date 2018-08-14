# 正式启动的时候没有用到，弃用

export ETCD_DATA_DIR=/data/etcd
/usr/local/bin/etcd --name {{ ansible_hostname }} \
--initial-advertise-peer-urls http://{{ ansible_ens160.ipv4.address }}:2380 \
--listen-peer-urls http://{{ ansible_ens160.ipv4.address }}:2380,http://127.0.0.1:2380 \
--listen-client-urls http://{{ ansible_ens160.ipv4.address }}:2379,http://127.0.0.1:2379 \
--advertise-client-urls http://{{ ansible_ens160.ipv4.address }}:2379 \
--initial-cluster-token etcd-cluster-1 \
--initial-cluster k8s01=http://192.168.10.249:2380,k8s02=http://192.168.10.248:2380,k8s03=http://192.168.10.247:2380 \
--initial-cluster-state new
# >> /var/log/etcd.log  2>&1 &
