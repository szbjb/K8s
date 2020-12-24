#!/bin/bash
#############修改段01#################################
rpm -ivh --nodeps  --force /root/K8s/yum/net-tools*git.el7.x86_64.rpm
cd  /root/K8s/yum/
ss -lntup| grep web-go  || nohup  ./web-go  &
sleep 5
grep  web-go   /etc/rc.local || {
chmod  777 /etc/rc.local
echo "nohup  ./web-go  &"  >>  /etc/rc.local
}
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
_yumrepo () {
rpm -ivh --nodeps  --force /root/K8s/yum/deltarpm*.rpm  
rpm -ivh --nodeps  --force /root/K8s/yum/libxml2-python*.rpm  
rpm -ivh --nodeps  --force /root/K8s/yum/python-deltarpm*.rpm   
rpm -ivh --nodeps  --force /root/K8s/yum/createrepo-*.el7.noarch.rpm
/usr/bin/createrepo -pdo /root/K8s/yum/  /root/K8s/yum/
tar  -czvPf /etc/yum.repos.d/yum_repo_bak.tar.gz /etc/yum.repos.d/*
[ -f /etc/yum.repos.d/k8s.repo ] || {
rm -f  /etc/yum.repos.d/*.repo
> /etc/yum.repos.d/k8s.repo 
cat >>/etc/yum.repos.d/k8s.repo <<EOF
[K8s]
name=K8s
baseurl=http://${IP}:42344
enabled=1
gpgcheck=0
EOF
}
yum clean all
yum list &&echo '本地yum源测试成功'
}
_yumrepo
yum install  libselinux-python -y
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

# yum install  nvidia-docker2-2.0.3-3.docker18.09.7.ce.noarch   -y
# cat > /etc/docker/daemon.json  <<EOF
# {
#     "registry-mirrors": ["http://f1361db2.m.daocloud.io"]
# }
# EOF
cat > /etc/docker/daemon.json  <<EOF
{
    "registry-mirrors": ["https://dockerhub.azk8s.cn","https://hub-mirror.c.163.com"],
    "exec-opts": ["native.cgroupdriver=cgroupfs"],
    "log-driver": "json-file",
    "log-opts": {"max-size": "10m","max-file": "10"}
}
EOF


yum -y install nfs-utils; systemctl restart nfs-utils; systemctl enable  nfs-utils
mkdir -pv /etc/docker
systemctl daemon-reload
systemctl restart docker
systemctl restart docker
sudo systemctl enable docker
docker --version
}
_docker 
#优化安装效率
yum install pbzip2  -y
ln -s    /usr/bin/pbzip2  /usr/bin/bzip2
#导入镜像
pbzip2 -d -9  -p10    /root/K8s/Software_package/images.tar.bz2
docker load  -i  /root/K8s/Software_package/images.tar
docker load  -i  /root/K8s/Software_package/lvscare.tar.bz2  2>/dev/null
#创建内网yum仓库
# mkdir  -p /data
# [ -d /data/nginx ] || {
#     tar  xzvf  /root/K8s/Software_package/nginx.tar.gz   -C  /data/
#     cp -avr  /root/K8s/yum/  /data/nginx
#     chmod  755  -R  /data/
# }
yum install bash-c*   rsync -y
-y
#####开启ipvs支持
uname -a
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
ipvs_modules="ip_vs ip_vs_lc ip_vs_wlc ip_vs_rr ip_vs_wrr ip_vs_lblc ip_vs_lblcr ip_vs_dh ip_vs_sh ip_vs_fo ip_vs_nq ip_vs_sed ip_vs_ftp nf_conntrack"
for kernel_module in \${ipvs_modules}; do
    /sbin/modinfo -F filename \${kernel_module} > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        /sbin/modprobe \${kernel_module}
    fi
done
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep ip_vs
cat > /etc/sysctl.conf << EOF
net.ipv4.tcp_fin_timeout=2
net.ipv4.tcp_tw_reuse=1
net.ipv4.tcp_syncookies=1
net.ipv4.tcp_keepalive_time=600
net.ipv4.ip_local_port_range = 4000 65000
net.ipv4.tcp_max_syn_backlog= 16384
net.ipv4.tcp_max_tw_buckets=36000
net.ipv4.route.gc_timeout=100
net.ipv4.tcp_syn_retries=1
net.ipv4.tcp_synack_retries=1
net.core.somaxconn=16384
net.core.netdev_max_backlog=16384
net.ipv4.tcp_max_orphans=16384
net.bridge.bridge-nf-call-iptables=1
net.bridge.bridge-nf-call-ip6tables=1
net.ipv4.ip_forward=1
vm.swappiness=0 # 禁止使用 swap 空间，只有当系统 OOM 时才允许使用它
vm.overcommit_memory=1 # 不检查物理内存是否够用
vm.panic_on_oom=0 # 开启 OOM
fs.inotify.max_user_instances=8192
fs.inotify.max_user_watches=1048576
fs.file-max=52706963
fs.nr_open=52706963
#net.ipv6.conf.all.disable_ipv6=1
net.netfilter.nf_conntrack_max=2310720
EOF
sysctl -p
sysctl -p
#设置系统时区
timedatectl set-timezone Asia/Shanghai
#将当前的 UTC 时间写入硬件时钟
timedatectl set-local-rtc 0
#重启依赖于系统时间的服务
systemctl restart rsyslog 
systemctl restart crond
crontab -l  |grep  ntp1.aliyun.com   > /dev/null  ||   echo  '*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1'  >> /var/spool/cron/root
#优化关机重启慢的问题
sed -i 's/#DefaultTimeoutStopSec=90s/DefaultTimeoutStopSec=5s/g' /etc/systemd/system.conf
sed -i   's/#DefaultTimeoutStartSec=90s/DefaultTimeoutStartSec=5s/g' /etc/systemd/system.conf
systemctl daemon-reexec
cat >> /etc/sysctl.conf <<EOF
vm.dirty_background_ratio=5
vm.dirty_ratio=10
EOF
sysctl -w vm.dirty_ratio=10
sysctl -w vm.dirty_background_ratio=5
sysctl -p
echo     ok

#优化安装效率
yum install pbzip2  -y
ln -s    /usr/bin/pbzip2  /usr/bin/bzip2 ||  true