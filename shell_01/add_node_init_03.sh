#!/bin/bash
#新增节点初始化安装docker-ce note节点执行
systemctl   is-active     kubelet kube-proxy docker && {
    echo "跳过已存在节点"
    exit 0
}
echo  "后台安装中...这里时间比较长 耐心等待"
yum clean all
yum list &&echo '本地yum源测试成功'

#k8s初始化环境
cat>/etc/sysctl.d/kubernetes.conf<<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
EOF
sysctl -p /etc/sysctl.d/kubernetes.conf>&/dev/null
##########
# sleep 1
sed  's/TimeoutSec=0/TimeoutSec=200/g' /usr/lib/systemd/system/rc-local.service -i
sed -i 's#=enforcing#=disabled#g' /etc/selinux/config
setenforce 0
getenforce
systemctl stop firewalld.service
systemctl disable firewalld.service

#####docker
_docker  (){
yum install docker-ce   -y
systemctl start docker
docker -v

yum install  nvidia-docker2-2.0.3-3.docker18.09.7.ce.noarch   -y
cat > /etc/docker/daemon.json  <<EOF
{
    "registry-mirrors": ["http://f1361db2.m.daocloud.io"]
}
EOF
mkdir -pv /etc/docker
systemctl daemon-reload
systemctl restart docker
systemctl restart docker
sudo systemctl enable docker
docker --version
}
_docker 
#导入镜像
docker  load  -i  /opt/images.tar.bz2

#安装flannel网络组件
master_ip=$(grep  baseurl= /etc/yum.repos.d/k8s.repo |awk  -F ":"  '{print $2}'|sed  's/\/\///g')
rpm -aq | grep net-tools   ||  yum install net-tools -y  >   /dev/null
#检测本机master IP地址
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
sed  "s/$master_ip/$IP/g"   /etc/kubernetes/kubelet.conf   -i
sed  "s/v=4/v=4  --address=${IP}/g"    /etc/kubernetes/kubelet.conf  -i
sed  "s/$master_ip/$IP/g"   /etc/kubernetes/ssl/*  -i
sed  "s/$master_ip/$IP/g"     /etc/kubernetes/kube-proxy.conf  -i
sed -i.bak -e '/ExecStart/i EnvironmentFile=\/run\/flannel\/subnet.env' -e 's/ExecStart=\/usr\/bin\/dockerd/ExecStart=\/usr\/bin\/dockerd $DOCKER_NETWORK_OPTIONS/g' /usr/lib/systemd/system/docker.service
systemctl daemon-reload
systemctl enable flanneld --now
systemctl restart docker
systemctl status flanneld || systemctl restart  flanneld
systemctl status docker
ip address show

yum install -y nfs-utils rpcbind
 systemctl restart rpcbind
  systemctl enable rpcbind
 systemctl enable nfs
 systemctl restart nfs

#安装note组件
systemctl daemon-reload
systemctl enable kube-proxy.service --now
sleep 10
systemctl status kube-proxy.service -l


systemctl daemon-reload
systemctl enable kubelet.service --now
sleep 10
systemctl status kubelet.service -l
#增加存储支持
yum install glusterfs-fuse socat glusterfs  -y 
modprobe dm_snapshot;modprobe dm_mirror;modprobe dm_thin_pool