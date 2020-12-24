#!/bin/bash
#k8s集群版专用
_single  ()  {
 yum install -y nfs-utils rpcbind
mkdir -pv  /data/nfs/k8s
chown -R nfsnobody.nfsnobody /data/nfs/k8s
echo  '/data/nfs/k8s  *(rw,async,no_root_squash)'   >> /etc/exports
 systemctl restart rpcbind
 systemctl enable rpcbind
 systemctl enable nfs
 systemctl restart nfs

}
_single

