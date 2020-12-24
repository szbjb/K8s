#!/bin/bash
#单机版

IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))

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

_master_nfs  ()  {
# cd /root/K8s/nfs/; helm install --name my-nfs-client  --set nfs.server=${IP} --set "nfs.path=/data/nfs/k8s  ,storageClass.name=gluster-heketi"  ./nfs-client-provisioner/
cd /root/K8s/nfs/; helm install  my-nfs-client  --set nfs.server=${IP} --set "nfs.path=/data/nfs/k8s  ,storageClass.name=gluster-heketi"  ./nfs-client-provisioner/
}
_master_nfs
#helm install   --name my-nfs-client  --set nfs.server=192.168.123.40 --set "nfs.path=/data/nfs  ,storageClass.name=gluster-heketi"   ../nfs-client-provisioner/
#定义storageClass.name为 gluster-heketi
#删除 helm  delete  my-nfs-client; helm del --purge my-nfs-client
 kubectl patch storageclass  gluster-heketi  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  