#!/bin/bash
#k8s集群版专用
IP=$(cat /root/K8s/nfs_ip.txt)

#安装服务端
ansible $IP -m script -a "chdir=/tmp  /root/K8s/nfs/Cluster_nfs/nfs_install_02.sh"
#安装客户端
cd /root/K8s/nfs/; helm install   my-nfs-client  --set nfs.server=${IP} --set "nfs.path=/data/nfs/k8s  ,storageClass.name=gluster-heketi"  ./nfs-client-provisioner/

#helm install   --name my-nfs-client  --set nfs.server=192.168.123.40 --set "nfs.path=/data/nfs  ,storageClass.name=gluster-heketi"   ../nfs-client-provisioner/
#定义storageClass.name为 gluster-heketi
#删除 helm  delete  my-nfs-client; helm del --purge my-nfs-client   

 kubectl patch storageclass  gluster-heketi  -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'  