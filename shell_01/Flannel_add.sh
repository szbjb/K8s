#!/bin/bash
# 3.5 部署Flannel网络
# 由于Flannel需要使用etcd存储自身的一个子网信息，所以要保证能成功连接Etcd，写入预定义子网段。写入的Pod网段${CLUSTER_CIDR}必须是/16段地址
# ，必须与kube-controller-manager的–-cluster-cidr参数值一致。一般情况下，在每一个Node节点都需要进行配置，执行脚本KubernetesInstall-08.sh。
#####ip环境
#####ip环境
#拷贝相关秘钥
scp -r  /etc/etcd  /etc/kubernetes/   192.168.123.24:/etc
scp  /usr/local/bin/{flanneld,mk-docker-opts.sh}   192.168.123.24:/usr/local/bin/
scp  /usr/lib/systemd/system/flanneld.service   192.168.123.24:/usr/lib/systemd/system/

ansible $IP -m copy -a "src=/etc/etcd  dest=/etc/"
ansible $IP -m copy -a "src=/etc/kubernetes  dest=/etc/"
# Modify the docker service.
sed -i.bak -e '/ExecStart/i EnvironmentFile=\/run\/flannel\/subnet.env' -e 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd $DOCKER_NETWORK_OPTIONS/g' /usr/lib/systemd/system/docker.service

# Start or restart related services.
systemctl daemon-reload
systemctl enable flanneld --now
systemctl restart docker
systemctl status flanneld || systemctl restart  flanneld
systemctl status docker
ip address show
