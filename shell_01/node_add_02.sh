#!/bin/bash
#添加Node节点
#配置内网yum源
#检测本机master IP地址
cd /tmp
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))


for  VAR_IP in $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt|xargs)
    do
       ansible $VAR_IP -m shell -a   "rm -f  /etc/yum.repos.d/*.repo"
       ansible $VAR_IP -m shell -a   " echo  \"[K8s]\"   > /etc/yum.repos.d/k8s.repo "
       ansible $VAR_IP -m shell -a   " echo  \"name=K8s\"   >> /etc/yum.repos.d/k8s.repo "
       ansible $VAR_IP -m shell -a   " echo  \"baseurl=http://${IP}:42344\"   >> /etc/yum.repos.d/k8s.repo "
       ansible $VAR_IP -m shell -a   " echo  \"enabled=1\"   >> /etc/yum.repos.d/k8s.repo  "
       ansible $VAR_IP -m shell -a   " echo  \"gpgcheck=0\"   >> /etc/yum.repos.d/k8s.repo  "
       ansible $VAR_IP -m shell -a   "yum  repolist"
       scp  /root/K8s/Software_package/images.tar.bz2    $VAR_IP:/opt
       scp  /usr/local/bin/{flanneld,mk-docker-opts.sh}  $VAR_IP:/usr/local/bin/
       scp   /usr/lib/systemd/system/flanneld.service   $VAR_IP:/usr/lib/systemd/system/
       scp  -r  /etc/etcd/  /etc/kubernetes/    $VAR_IP:/etc
       ansible $VAR_IP -m shell -a   "rm -f /etc/kubernetes/ssl/kubelet*"
       ###传输Note所需
       scp  /usr/local/bin/{kube-proxy,kubelet}    $VAR_IP:/usr/local/bin
       scp  /usr/lib/systemd/system/kube-proxy.service   $VAR_IP:/usr/lib/systemd/system/
       scp  /usr/lib/systemd/system/kubelet.service  $VAR_IP:/usr/lib/systemd/system/
       scp  /root/K8s/shell_01/add_node_init_03.sh    $VAR_IP:/tmp
done

#init


