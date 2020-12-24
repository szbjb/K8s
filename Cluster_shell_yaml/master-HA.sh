#!/bin/bash
#master节点2上面执行
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))

. /root/K8s/ip_2.txt
master_ip=${master_hosts_}
# master_ip=10.10.8.170
KUBE_ETC=/etc/kubernetes
KUBE_API_CONF=/etc/kubernetes/apiserver.conf
scp  $master_ip:/usr/local/bin/{kube-apiserver,kube-scheduler,kube-controller-manager,kubectl,helm}  /usr/local/bin/

# scp !(kubelet-client-*) -r $master_ip:/etc/kubernetes/  /etc/
rsync -avz -e ssh --exclude='kubelet-client-*' --exclude='kube-proxy.conf' --exclude='kube-proxy.kubeconfig'  --exclude='kubelet*'   root@$master_ip:/etc/kubernetes/  /etc/kubernetes/


# scp  -r $master_ip:/etc/kubernetes/pod-01/*  /etc/kubernetes/pod/
# scp  $master_ip:$KUBE_ETC/token.csv  $KUBE_ETC/
# scp  $master_ip:$KUBE_API_CONF  $KUBE_API_CONF
scp  $master_ip:/usr/lib/systemd/system/kube-apiserver.service  /usr/lib/systemd/system/kube-apiserver.service
. /root/K8s/ip_2.txt
sed  "s/=${master_hosts_}/=${IP}/g"  $KUBE_API_CONF  -i

systemctl daemon-reload
systemctl enable kube-apiserver.service --now
systemctl status kube-apiserver.service

#kube-scheduler
KUBE_ETC=/etc/kubernetes
KUBE_SCHEDULER_CONF=$KUBE_ETC/kube-scheduler.conf

scp  $master_ip:/usr/lib/systemd/system/kube-scheduler.service  /usr/lib/systemd/system/kube-scheduler.service
systemctl daemon-reload
systemctl enable kube-scheduler.service --now
sleep 10
systemctl status kube-scheduler.service
# kube-controller服务
KUBE_CONTROLLER_CONF=/etc/kubernetes/kube-controller-manager.conf
scp  $master_ip:/usr/lib/systemd/system/kube-controller-manager.service  /usr/lib/systemd/system/kube-controller-manager.service

systemctl daemon-reload
systemctl enable kube-controller-manager.service --now
sleep 10
systemctl status kube-controller-manager.service



kubectl get cs
grep completion /root/.bash_profile  || echo   'source <(kubectl completion bash)'  >> /root/.bash_profile
grep helm /etc/profile || echo  'source <(helm completion bash)'  >>/etc/profile




###ipvs负载
# curl  -o   lvscare.tar.bz2   http://www.linuxtools.cn:19999/chfs/shared/lvscare.tar.bz2
# docker  load -i lvscare.tar.bz2
# docker run -it  --name lv  --net=host   -u root   fanux/lvscare:latest   bash
# docker run -it  --name lv  --net=host   -u root --privileged   registry.cn-chengdu.aliyuncs.com/set/k8s/lvscare:v1.0 bash   
# cat > /etc/apt/sources.list << 'EOF'
# deb http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic-security main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic-updates main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic-proposed main restricted universe multiverse

# deb http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse
# deb-src http://mirrors.aliyun.com/ubuntu/ bionic-backports main restricted universe multiverse

# EOF


# apt update  &&  apt install curl ipvsadm      iproute2 -y


# lvscare care --vs 10.103.97.123:6443 --rs  10.10.8.170:6443 --rs  10.10.8.160:6443 \
# --health-path / --health-schem https

# sealos init --passwd 456 \
# 	--master 10.10.8.170  --master 10.10.8.160   \
# 	--node 10.10.8.165  --node   10.10.8.166 \
# 	--pkg-url /root/kube1.17.0.tar.gz \
# 	--version v1.17.0




# sealos init --passwd 123456 \
# 	--master 192.168.0.2  --master 192.168.0.3  --master 192.168.0.4  \
# 	--node 192.168.0.5 \
# 	--pkg-url /root/kube1.16.0.tar.gz \
# 	--version v1.16.0



#  /usr/bin/lvscare care --vs 192.168.123.11:6443 --health-path /healthz --health-schem https --rs 10.10.8.170:6443 --rs 10.10.8.160:6443

# curl  -k  --header  "Authorization: Bearer f752ef15eca90a5d45d2097cfcfcbc6d" https://10.103.97.123:6443/version
#  /usr/bin/lvscare care --vs 10.103.97.12:6443 --health-path /healthz --health-schem https --rs 10.10.8.170:6443  --rs 10.10.8.160:6443 


# lvscare care --vs 10.103.97.12:6443 --rs 192.168.2.228:8081 --rs 192.168.2.228:8082 --rs 192.168.2.228:8083 \
# --health-path / --health-schem http

# lvscare care --vs 10.103.97.12:6443 --rs 10.10.8.170:6443 --rs  10.10.8.160:6443   \
# --health-path / --health-schem http


# rpm -ivh https://mirrors.aliyun.com/centos/7.7.1908/os/x86_64/Packages/ipvsadm-1.27-7.el7.x86_64.rpm?spm=a2c6h.13651111.0.0.39d12f70NXDQLx&file=ipvsadm-1.27-7.el7.x86_64.rpm
# rm -f /usr/bin/lvscare; curl -s  -o /usr/bin/lvscare   http://www.linuxtools.cn:42344/lvscare
# chmod  777 /usr/bin/lvscare 


# ipvsadm -C

# ipvsadm -ln
#node节点修改vip地址
sed  "s/${master_ip}/${IP}/g"  -i  /etc/kubernetes/*config
sed  "s/${master_ip}/${IP}s/g"  -i  /etc/kubernetes/ssl/bootstrap.kubeconfig
# sed  "s/=${master_ip}/=10.103.97.123/g"  -i /etc/kubernetes/apiserver.conf
# ansible node -m shell -a "sed  \"s/${master_ip}/10.103.97.123/g\"  -i  /etc/kubernetes/*config"
# ansible node -m shell -a "sed  \"s/${master_ip}/10.103.97.123/g\"  -i  /etc/kubernetes/ssl/bootstrap.kubeconfig"
systemctl restart kube-proxy
systemctl restart kubelet
#
#
sleep 10
/usr/local/bin/kubectl label node ${IP}  node-role.kubernetes.io/Master_Ha=true
/usr/local/bin/kubectl label node ${master_ip}  node-role.kubernetes.io/Master_Ha=true