#!/bin/bash

status=`/usr/local/bin/etcdctl get /k8s/network/config/`
if [ status -ne 0 ];then
  /usr/local/bin/etcdctl --endpoint=http://192.168.10.247:2379 mk /k8s/network/config '{"Network":"10.211.200.0/16", "SubnetLen":24, "Backend":{"Type":"vxlan"}}' &&
  /usr/local/bin/etcdctl --endpoint=http://192.168.10.247:2379 mkdir /k8s/network
else
  exit 0
fi
