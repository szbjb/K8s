#!/bin/bash
#本地yum源
rpm -ivh --nodeps  --force /root/K8s/yum/net-tools-*git.el7.x86_64.rpm
cd  /root/K8s/yum/
chmod  777 web-go
kill  -9  $(ss -lntup| grep web|awk   -F "pid="  '{print  $2}'|awk  -F ','   '{print $1}')
ss -lntup| grep web-go || nohup  ./web-go  &
sleep 5
grep  web-go   /etc/rc.local || {
chmod  777 /etc/rc.local
echo "nohup  ./web-go  &"  >>  /etc/rc.local
}
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
_yumrepo () {
rpm -ivh --nodeps  --force /root/K8s/yum/deltarpm*.rpm  
rpm -ivh --nodeps  --force /root/K8s/yum/libxml2-python*.rpm  
rpm -ivh --nodeps  --force /root/K8s/yum/python-deltarpm-*.rpm   
rpm -ivh --nodeps  --force /root/K8s/yum/createrepo-*.noarch.rpm
/usr/bin/createrepo -pdo /root/K8s/yum/  /root/K8s/yum/
tar  -czvPf /etc/yum.repos.d/yum_repo_bak.tar.gz /etc/yum.repos.d/*
rm -f  /etc/yum.repos.d/*.repo
> /etc/yum.repos.d/k8s.repo 
cat >/etc/yum.repos.d/k8s.repo <<EOF
[K8s]
name=K8s
baseurl=http://${IP}:42344
enabled=1
gpgcheck=0
EOF
yum clean all
yum list ||{
echo '本地yum源测试成功'
exit 1
}
#关闭防火墙selinux
sed  's/TimeoutSec=0/TimeoutSec=200/g' /usr/lib/systemd/system/rc-local.service -i
sed -i 's#=enforcing#=disabled#g' /etc/selinux/config
setenforce 0
getenforce
systemctl stop firewalld.service
systemctl disable firewalld.service
sed -i 's@.*UseDNS yes@UseDNS no@' /etc/ssh/sshd_config
#优化内核
}
_yumrepo

#获取集群ip
_cluster_ip  ()  {
if (whiptail --title "导入集群IP地址(包含本机ip默认第一个ip对应本机ip作为master)" --yes-button "YES" --no-button "NO"  --yesno "批量导入集群IP地址?" 10 60) then
    echo "You chose Skittles Exit status was $?."
    echo  ok
    rm -f   /root/K8s/ip.txt*
    rm -f   /root/K8s/ip.txt
    > /root/K8s/ip.txt
cat >  /root/K8s/ip.txt <<EOF
#按下字母i键进入编辑模式,将ip批量粘贴进来即可
#格式如下(不包含#号),导入完毕后wq退出即可继续后面的操作
#这里填写整个集群的ip包含本机master的ip，ip不能重复，不要有空行
#x.x.x.x
#x.x.x.x
#x.x.x.x
EOF
    vi /root/K8s/ip.txt
    echo  IP导入完毕
else
    echo "You chose M&M's. Exit status was $?."
    echo  no
    exit 1
fi
}

_db_ip () {
db_ip=$(sed '/^\s*$/d'   /root/K8s/ip.txt  | grep  "^#"   -v |wc -l)
if (whiptail --title "启用k8s集群动态存储持久化方案Heketi+GlusterFS存储?" --yesno "是否启用k8s集群动态存储持久化方案Heketi+GlusterFS存储最低3台及以上(也就是最低三个节点,且都存在未分区的硬盘)，且存在未使用原始块设备(挂载一块新硬盘，且没有分区例如  /dev/sdx    。\n 存储节点的存储盘默认40%用于k8s集群持久化存储，剩余60%用于挂载到本机的/data目录  \n 请确认硬件情况是否满足，若不满足，请选'否'，取消启用k8s集群动态存储持久化功能'" 10 100) then
    var_c1=$?
else
    var_c1=$?
fi
[[ $var_c1  =  0 ]]   && {
echo  "发现集群数量足够开启k8s持久化分布式存储，是否现在导入存储ip(必须包含在整个集群内)默认最低2台"
if (whiptail --title "导入存储ip(必须包含在整个集群内)默认最低2台" --yes-button "YES" --no-button "NO"  --yesno "批量导入存储集群IP地址?" 10 60) then
    echo "You chose Skittles Exit status was $?."
    echo  ok
    >/tmp/db_ip.txt
    > /tmp/db_ip.txt
cat > /tmp/db_ip.txt <<EOF
#按下字母i键进入编辑模式,将ip批量粘贴进来即可
#首次使用此脚本安装集群数量至少2台及以上才能使用此功能，k8s集群持久化采用方案为kubernetes中部署Heketi(已持久化数据库)+GlusterFS
#默认40%的存储空间用于k8s持久化存储，余下60%存储空间挂载到 /data目录，默认分区格式 xfs
#存储最低2台，且存在未使用原始块设备(挂载一块硬盘，且没有分区例如  /dev/sdb)
#2台副本数为2,3台或者超过三台副本数为3,默认开启动态存储 storageclasses 为gluster-heketi，测试pvc为gluster1-test
#格式如下(不包含#号,不能有空行,仅填写需要加入存储集群的ip默认为),导入完毕后wq! / x! 退出即可继续后面的操作
#x.x.x.x
#x.x.x.x
#x.x.x.x
EOF
    vi /tmp/db_ip.txt
    echo  IP导入完毕
  
else
    echo "You chose M&M's. Exit status was $?."
    echo  no
    exit 1
fi

}
}
_Master_HA_ip () {
db_ip=$(sed '/^\s*$/d'   /root/K8s/ip.txt  | grep  "^#"   -v |wc -l)
if (whiptail --title "启用k8s集群多master高可用?(注意:该功能为目前实验性功能,仅供测试.谨慎选择)" --yesno "是否启用多master高可用基于内核ipvs负载高可用,本机已默认为master-1不可更改,只需要在下面的步骤中增加master节点的IP即可\n 不能包含本机IP,多master高可用至少需要3个节点 \n 请确认集群情况是否满足，若不满足，请选'否'，取消启用k8s集群多master高可用功能'" 10 100) then
    var_c2=$?
else
    var_c2=$?
fi
[[ $var_c2  =  0 ]]   && {
echo  "开启master高可用(基于内核ipvs)，是否现在导入HA-masterip(必须包含在整个集群内)默认最低1台"
if ( whiptail --title "导入master-HA-ip(必须包含在整个集群内,不包含本机IP,别填本机IP.本机默认为master之一)最低填写1台及以上" --yes-button "YES" --no-button "NO"  --yesno "批量导入master-HA集群IP地址?" 10 120) then
    echo "You chose Skittles Exit status was $?."
    echo  ok
    >/tmp/ha_ip.txt
    > /tmp/ha_ip.txt
cat > /tmp/ha_ip.txt <<EOF
#按下字母i键进入编辑模式,将ip批量粘贴进来即可
#首次使用此脚本安装集群数量至少3台及以上才能使用此功能，k8s集群多master高可用采用基于内核的负载高可用方案
#vip地址默认为10.103.97.123
#此步骤不要填写本机IP 不要填写本机IP  本机默认作为master节点之一.此步骤只需要填写需要增加的master节点即可
#格式如下(不包含#号,不能有空行,仅填写需要加入存储集群的ip默认为),导入完毕后wq! / x! 退出即可继续后面的操作
#x.x.x.x
#x.x.x.x
#x.x.x.x
EOF
    vi /tmp/ha_ip.txt
    echo  IP导入完毕
  
else
    echo "You chose M&M's. Exit status was $?."
    echo  no
    exit 1
fi

}
}






#初始化集群环境,不安装k8s集群
_Cluste_jiqun_One_click   ()  {
#获取集群ip
#选择持久化方案
_cluster_ip
#获取节点数(超过大于1 启用持久化方案)
var_num_ip=$(grep  -v "^#" /root/K8s/ip.txt |sed '/^$/d'|wc   -l)
_menu_B
# [[ $var_num_ip -ge 2 ]]   &&  _db_ip
rpm -aq | grep net-tools   ||  yum install net-tools -y  >   /dev/null

#开启master_HA
var_num_ip=$(grep  -v "^#" /root/K8s/ip.txt |sed '/^$/d'|wc   -l)
[[ $var_num_ip -ge 3 ]]   && _Master_HA_ip

#检测本机master IP地址
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
password_=$(whiptail --title "#请输入集群服务器统一的root密码 并回车#" --passwordbox "请确认所有节点root密码一致,确定提交?" 10 60 3>&1 1>&2 2>&3)

master_hosts_=$(whiptail --title "#请输入本机Ip(master)并回车#" --inputbox "请检查IP是否一致,确定提交?" 10 60 "$IP" 3>&1 1>&2 2>&3)



#批处理ip.txt
grep -v  "^#" /root/K8s/ip.txt |sed  "/$master_hosts_/d" | awk '{for(i=1;i<=NF;i++){printf "slave+_hosts_="$i" "}{print ""}}' |awk -v RS="+" '{n+=1;printf $0n}'  > /root/K8s/ip_2.txt
sed -i '$d' /root/K8s/ip_2.txt   
sed "s/^.*${master_hosts_}.*$/k8s_master=${master_hosts_}/"  /root/K8s/ip_2.txt  -i
sed  "/$master_hosts_/d"  /root/K8s/ip_2.txt  -i
echo  "master_hosts_=$master_hosts_"  >>  /root/K8s/ip_2.txt



#检查ip连通性,生成集群ip配置文件路径:/root/K8s/ip_2.txt
. /root/K8s/ip_2.txt
for ips in   $( awk -F  "="   '{print  $2}'  /root/K8s/ip_2.txt |xargs)
do
        ping -c 2 -W 1 ${ips} 
        if [ $? -eq 0 ]; then
                echo "检查内网连通性"${ips}" is ok !"
        else
                echo ""${ips}" is not connected ....."
                echo ""${ips}"   所输入IP无效,安装终止"
                exit 1
        fi

done




#安装ansible 集群面交互环境
yum install ansible   libselinux-python   sshpass   -y   || {
echo yum故障,安装终止
exit 1
}

#ansible调优
sed  s/'#host_key_checking = False'/'host_key_checking = False'/g   /etc/ansible/ansible.cfg  -i
sed  s/'#pipelining = False'/'pipelining = True'/g   /etc/ansible/ansible.cfg  -i
sed  's/# command_warnings = False/command_warnings = False/g' /etc/ansible/ansible.cfg  -i
sed      '/^GSSAPI/s/yes/no/g;  /UseDNS/d; /Protocol/aUseDNS no'    /etc/ssh/sshd_config   -i
echo  'gather_facts: nogather_facts: no' >> /etc/ansible/ansible.cfg
systemctl restart  sshd
#
#清除本地ssh环境
\rm -f ~/.ssh/*
#创建秘钥对
ssh-keygen -t dsa -f /root/.ssh/id_dsa -N  ""   &>/dev/null

#配置免交互登录
for  ip  in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt|xargs)
do
sshpass   -p  "$password_"  ssh-copy-id   -i  /root/.ssh/id_dsa.pub   root@$ip   -o StrictHostKeyChecking=no 

if [ $? -eq 0 ] 
    then
    echo   " host  $ip     成功！！！！"
            else
            echo   " host  $ip    失败!!!!" 
	    exit 1 
	
fi  
done



###配置ansible hosts文件
grep   master /etc/ansible/hosts  || {
cat >>/etc/ansible/hosts<<EOF
[master]
$master_hosts_


[slave]
$(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt|grep -v $master_hosts_)


[all]
$master_hosts_
$(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt|grep -v $master_hosts_)


EOF
}
#导入db节点ip到ansible
grep   '\[db\]'  /etc/ansible/hosts || sed '/^\s*$/d'   /tmp/db_ip.txt | grep  "^#"   -v |sed  '1 i\[db]'    >> /etc/ansible/hosts 
###
#导入ha-master节点ip到ansible
[  -f  /tmp/ha_ip.txt ] && {
grep   '\[Master_ha\]'  /etc/ansible/hosts || sed '/^\s*$/d'   /tmp/ha_ip.txt | grep  "^#"   -v |sed  '1 i\[Master_ha]'    >> /etc/ansible/hosts 
}
###
##note节点ssh优化
#
ansible  all  -m shell -a "sed      '/^GSSAPI/s/yes/no/g;  /UseDNS/d; /Protocol/aUseDNS no'    /etc/ssh/sshd_config   -i"
ansible  all  -m shell -a "systemctl restart sshd"
##ssh优化

echo    
echo "=============end=====END========================" 
#检测分发效果连通性,批量配置主机名
for var_2 in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt|grep $master_hosts_ -v|xargs)
do
  echo "==============host  $ip  info============================"
   grep  master /etc/hostname    ||  hostnamectl  set-hostname  K8s-master
   hostnamectl  set-hostname  K8s-master
   let u+=i
   let i+=1
   ssh root@$var_2  " hostnamectl  set-hostname  K8s-node${i}"
   echo  "K8s-node${i}-$var_2"
done
        



echo "===========END==================END====================="



#拷贝安装文件至slave节点
flannel_file_name=$(ls /root/K8s/Software_package/flannel-v*-linux-amd64.tar.gz |head  -n 1 |awk   -F  /  '{print  $NF}')
etcd_file_name=$(ls /root/K8s/Software_package/etcd-v*-linux-amd64.tar.gz |head  -n 1 |awk   -F  /  '{print  $NF}')

cat  >  /root/K8s/Cluster_shell_yaml/copy.yaml   <<EOF
- hosts: [all]
  tasks:
    - name: 系统初始化
      shell: systemctl stop firewalld.service
    - name: 系统初始化
      shell: sed  's/TimeoutSec=0/TimeoutSec=200/g' /usr/lib/systemd/system/rc-local.service -i    || true
    - name: 系统初始化
      shell: setenforce 0  || true
    - name: 系统初始化
      shell: getenforce
    - name: 系统初始化
      shell: sed -i 's#=enforcing#=disabled#g' /etc/selinux/config || true
    - name: 系统初始化
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/expect-5.45-14.el7_1.x86_64.rpm
    - name: 系统初始化
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/tcl-8.5.13-8.el7.x86_64.rpm
    - name: 系统初始化
      shell: mkdir   -pv /root/K8s/Software_package/
    - name: 系统初始化
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/tcl-8.5.13-8.el7.x86_64.rpm
    - name: 系统初始化
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/psmisc-22.20-16.el7.x86_64.rpm
    - name: 卸载增强
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/yum_ntfs/gnutls-3.3.29-9.el7_6.x86_64.rpm      ||true
    - name: 卸载增强
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/yum_ntfs/nettle-2.7.1-8.el7.x86_64.rpm      ||true
    - name: 卸载增强
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/yum_ntfs/trousers-0.3.14-2.el7.x86_64.rpm      ||true
    - name: 卸载增强
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/yum_ntfs/ntfsprogs-2017.3.23-11.el7.x86_64.rpm      ||true
    - name: 卸载增强
      shell: rpm -ivh --nodeps  --force  http://${IP}:42344/yum_ntfs/sshpass-1.06-2.el7.x86_64.rpm      ||true
- hosts: [slave]
  tasks:
    - name: 1拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/Software_package/$flannel_file_name  dest=/root/K8s/Software_package  force=no
    - name: 2拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/Software_package/$etcd_file_name  dest=/root/K8s/Software_package  force=no
    - name: 3拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/Cluster_shell_yaml/  dest=/root/K8s/Cluster_shell_yaml/  force=no
    - name: 4拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/single_shell/ dest=/root/K8s/single_shell/  force=no
    - name: 4拷贝安装文件到slave节点<a01>
      copy: src=/etc/yum.repos.d/k8s.repo dest=/etc/yum.repos.d/k8s.repo  force=no
    - name: 4拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/ip_2.txt dest=/root/K8s/ip_2.txt  force=no
    - name: 4拷贝安装文件到slave节点<a01>
      copy: src=/root/K8s/ip.txt dest=/root/K8s/ip.txt  force=no
    - name: 执行系统初始化脚本<a02>
      shell: rpm -ivh --nodeps  --force /root/K8s/yum/deltarpm*.rpm
      shell: rpm -ivh --nodeps  --force /root/K8s/yum/libxml2-python-*.rpm
      shell: rpm -ivh --nodeps  --force /root/K8s/yum/python-deltarpm*.rpm
      shell: rpm -ivh --nodeps  --force /root/K8s/yum/createrepo-*.noarch.rpm
      shell: /usr/bin/createrepo -pdo /root/K8s/yum/  /root/K8s/yum/
      shell: yum clean all
      shell: yum list echo '本地yum源测试成功'
      shell: echo '本地yum源测试成功'
    - name: ansible客户端插件安装install_libselinux-python<a03>
      yum: name=libselinux-python state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_ntp<a04>
      yum: name=ntp    state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_net-tools<a05>
      yum: name=net-tools   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_net-tools<a06>
      yum: name=net-tools   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_sshpass<a07>
      yum: name=sshpass   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_sshpass<a08>
      yum: name=rsync   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_glusterfs<a08>
      yum: name=glusterfs   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装install_glusterfs-fuse<a08>
      yum: name=glusterfs-fuse   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装socat<a09>
      yum: name=socat   state=latest  disable_gpg_check=yes
- hosts: [slave]
  gather_facts: no
  vars:
    testpath1: "/root/K8s/Software_package/images.tar.bz2"
    testpath2: "/root"
  tasks:
    - debug:
        msg: "file"
    - name: 1拷贝安装文件到slave节点<a02>
      copy: src=/root/K8s/Software_package/images.tar.bz2  dest=/root/K8s/Software_package  force=no
      when: testpath1 is file  
- hosts: [master]
  tasks:
    - name: ansible客户端插件安装install_glusterfs-fuse<a08>
      yum: name=bash-completion   state=latest  disable_gpg_check=yes
    - name: ansible客户端插件安装socat<a09>
      yum: name=socat   state=latest  disable_gpg_check=yes
      yum: name=bash-completion-extras   state=latest  disable_gpg_check=yes

EOF

# cat >/etc/yum.repos.d/k8s.repo <<EOF
# [K8s]
# name=K8s
# baseurl=http://${IP}:42344
# enabled=1
# gpgcheck=0
# EOF



ansible slave  -m  shell -a  "tar  -czvPf /etc/yum.repos.d/yum_repo_bak.tar.gz /etc/yum.repos.d/*"
ansible slave  -m  shell -a  "rm -f  /etc/yum.repos.d/*.repo"
# ansible slave  -m copy  -a  "src=/root/K8s/yum/K8s.repo   dest=/etc/yum.repos.d/"



#配置slave节点 本地Yum源
# ansible all  -m shell -a  "yum clean all "  >  /dev/null 
# ansible all  -m shell -a  " yum list "  >  /dev/null 
# yum_echo=$?
# if [ $yum_echo -ne 0 ]
#     then  
#数据传输至集群节点
ansible-playbook      /root/K8s/Cluster_shell_yaml/copy.yaml     -vvv
#        else
#        ansible slave  -m shell -a  " /usr/bin/rsync -av  $master_hosts_:/root/K8s/  /root/K8s/"
# fi

#配置集群面交互登录
#检测分发效果连通性
for var_3 in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_2.txt  | grep -v $master_hosts_ |xargs)
do
  echo "==============host  $var_3  info============================"
    ssh root@$var_3 "rm -f  /root/.ssh/id_dsa"
    ssh root@$var_3 "ssh-keygen -t dsa -f /root/.ssh/id_dsa -N  \"\"   &>/dev/null"
    ssh root@$var_3 "sshpass   -p  "$password_"  ssh-copy-id   -i  /root/.ssh/id_dsa.pub   root@$master_hosts_   -o StrictHostKeyChecking=no"
done

#时间同步ntp服务端客户端配置
#定时同步时间定时任务
crontab -l  |grep  ntp1.aliyun.com   > /dev/null  ||   echo  '*/5 * * * * /usr/sbin/ntpdate ntp1.aliyun.com >/dev/null 2>&1'  >> /var/spool/cron/root
yum install ntp  -y    
cat >/etc/ntp.conf <<EOF
driftfile /var/lib/ntp/drift
restrict default kod nomodify notrap nopeer noquery
restrict -6 default kod nomodify notrap nopeer noquery
restrict 127.0.0.1 
restrict -6 ::1
server 0.centos.pool.ntp.org iburst
server 1.centos.pool.ntp.org iburst
server 2.centos.pool.ntp.org iburst
includefile /etc/ntp/crypto/pw
keys /etc/ntp/keys
server 127.127.1.0  iburst   # local clock 使用本机时间作为时间服务的标准
fudge 127.127.1.0 stratum 10 #这个值不能太高0-15，太高会报错
EOF
cat >/etc/sysconfig/ntpd <<EOF
# Drop root to id 'ntp:ntp' by default.
OPTIONS="-u ntp:ntp -p /var/run/ntpd.pid -g"
SYNC_HWCLOCK=yes
EOF

#时间同步服务端启动,加开机自启
systemctl restart  ntpd.service
systemctl enable  ntpd.service
systemctl status  ntpd.service

#验证

#配置客户端同步时间
ansible slave  -m  shell -a  "crontab  -l| grep  $master_hosts_"    ||  {
        ansible slave  -m  cron   -a  "backup=yes  minute=*/5 hour=* day=*  month=* weekday=*  name=\"Time synchronization\"  job=\"/usr/sbin/ntpdate $master_hosts_  >/dev/null 2>&1\""
        ansible slave  -m  shell -a  "crontab  -l| grep  $master_hosts_" 
}
#同步时间
sleep 2 
echo 同步时间,检查ntp服务是否可用
sleep 2
echo 同步时间,检查ntp服务是否可用
sleep 2
echo 同步时间,检查ntp服务是否可用

clear 
sleep  5
ansible slave -m shell -a  "ntpdate  $master_hosts_;hostname;date"
echo   ansible环境配置结束,ntp时间同步配置结束
sleep 5
#

####################分割线##############################3
# #master节点配置dns服务
# yum install dnsmasq -y  
# systemctl restart dnsmasq
# systemctl enable   dnsmasq.service
# #更改配置文件
# cat > /etc/dnsmasq.conf  <<EOF
# resolv-file=/etc/resolv.dnsmasq.conf
# listen-address=127.0.0.1,$master_hosts_
# conf-dir=/etc/dnsmasq.d,.rpmnew,.rpmsave,.rpmorig
# addn-hosts=/etc/dnshosts/k8s
# EOF

# cat   > /etc/resolv.dnsmasq.conf  <<EOF
# # Generated by NetworkManager
# nameserver 223.5.5.5
# EOF

# #重启dnsmasq服务
# systemctl restart dnsmasq
# #更改本机dns  /etc/resolv.conf
# echo  "nameserver  $master_hosts_"  >> /etc/resolv.conf
# cat  >/etc/resolv.conf   <<  EOF
# # Generated by NetworkManager
# nameserver   $master_hosts_
# EOF


}

################ansible环境配置结束#############################ansible环境配置结束###########################
################ansible环境配置结束#############################ansible环境配置结束###########################
################ansible环境配置结束#############################ansible环境配置结束###########################
################ansible环境配置结束#############################ansible环境配置结束###########################

_Cluste_K8s_One_click    ()   {
#执行检测脚本(必须在master节点执行)


sh /root/K8s/Cluster_shell_yaml/Check.sh

sleep  3
if 
    test -s  /root/K8s/Cluster_shell_yaml/err_check.log 
      then 
           echo  "集群安装环境检测不通过，存在以下问题(更多记录请查看/root/K8s/Cluster_shell_yaml/err_check.log)"
           cat   /root/K8s/Cluster_shell_yaml/err_check.log
           exit 1
      else
          echo "集群安装环境检测通过,即将安装K8s集群环境"
fi


################33
#执行对应ansible剧本
_Cluster_install  () {
#集群系统初始化本地Yum  docker  jdk环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a01_k8s_init.sh_all.yaml     -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群初始化脚本执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#集群 Etcd环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a02_etcd_all.yaml     -vvv
sleep 0.5
ansible  all  -m  shell  -a  "systemctl  is-active  etcd" || {
echo "集群 Etcd环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#k8s master 环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a03_k8s_master.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s master 环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#k8s slave环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a04_k8s_slave.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s slave环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#开启master-HA
master_ha_list=$(ansible  Master_ha  -m ping |grep  SUCCESS|awk   '{print $1}' |wc -l)
master_ha_list02=$(ansible  Master_ha  -m ping |grep  SUCCESS|awk   '{print $1}')
[[ "$master_ha_list"   -ge   "1" ]]  &&  {
#ip处理
master_ha_re="$(ansible  Master_ha,master  -m ping |grep  SUCCESS|awk   '{print $1}')"
all_node="$(ansible all  -m ping |grep  SUCCESS|awk   '{print $1}')   "
true_node=$(echo    $all_node|xargs   -n 1 | egrep   -v  "$(echo    $master_ha_re|xargs|sed  's/ /|/g')")
#导入nodes节点ip到ansible
grep   '\[node\]'  /etc/ansible/hosts || echo  ${true_node}|xargs -n 1 | grep  "^#"   -v |sed  '1 i\[node]'    >> /etc/ansible/hosts 

mkdir  -pv /etc/kubernetes/pod-01/
>/etc/kubernetes/pod/lvs.conf
for var  in  $master_ha_list02   ;do echo "   --rs  $var:6443"  >> /etc/kubernetes/pod-01/lvs.conf;  sleep 0.1 ;done
echo "   --rs  $IP:6443"  >> /etc/kubernetes/pod-01/lvs.conf
cat > /etc/kubernetes/pod-01/lvscare-dp.yaml  << 'EOF'
apiVersion: v1
kind: Pod
metadata:
  name: lvscare
  namespace: kube-system
  labels:
    app: lvscare
spec:
  containers:
    - name: lvscare
      image: registry.cn-chengdu.aliyuncs.com/set/k8s/lvscare:v1.0
      ports:
        - name: web
          containerPort: 80
      securityContext:
        privileged: true
      command: ["/bin/sh","/root/start.sh"]
      volumeMounts:
           - name: lvscareconf
             mountPath: /configfiles/lvs.conf
  volumes:
  - name: lvscareconf
    hostPath:
     path: /etc/kubernetes/pod/lvs.conf
  hostNetwork: true
EOF

ansible node -m shell -a  "mkdir -pv /etc/kubernetes/pod/"
ansible node -m copy -a "src=/etc/kubernetes/pod-01/lvscare-dp.yaml   dest=/etc/kubernetes/pod/" 
ansible node -m copy -a "src=/etc/kubernetes/pod-01/lvs.conf  dest=/etc/kubernetes/pod/" 
#node节点修改vip地址
master_ip=${IP}
ansible node -m shell -a "sed  \"s/${master_ip}/10.103.97.123/g\"  -i  /etc/kubernetes/*config"
ansible node -m shell -a "sed  \"s/${master_ip}/10.103.97.123/g\"  -i  /etc/kubernetes/ssl/bootstrap.kubeconfig"
ansible node -m shell -a "systemctl restart kube-proxy;  systemctl restart kubelet"
#master-HA
ansible Master_ha -m script -a "chdir=/tmp /root/K8s/Cluster_shell_yaml/master-HA.sh "
sleep 5
ansible node -m shell -a "systemctl restart kubelet"
}

#k8s helm环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a05_k8s_helm.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s helm环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#k8s coredns环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a06_k8s_coredns.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s helm环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#k8s dashboard环境
ansible-playbook      /root/K8s/Cluster_shell_yaml/a07_k8s_dashboard.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s helm环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
#k8s prometheus环境
_k8s_prometheus  () {
ansible-playbook      /root/K8s/Cluster_shell_yaml/a08_k8s_prometheus.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s prometheus环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
}
#k8s grafan环境
_k8s_grafan  () {
ansible-playbook      /root/K8s/Cluster_shell_yaml/a09_k8s_grafan.yaml    -vvv
sleep 0.5
[ $? -ne 0 ] && {
echo "集群k8s grafan环境执行失败,安装终止，脚本路径/root/K8s/Cluster_shell_yaml/"
exit 1
}
}

}
# #执行K8s集群安装
_Cluster_install 





 }
#########fv#######################################################################

_menu_B (){
OPTION=$(whiptail --title "K8s,  Vision @ 2019" --menu "Choose your option" 20 65 13 \
"1" "NFS" \
"2" "GlusterFs"  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]
            then
                    case $OPTION in
                        1)  
                        #启用k8s集群nfs持久化方案
                         NFS_IP=$(whiptail --title "#请指定需要作为NFS服务端的Ip(默认使用该节点的/data目录作为nfs存储,为k8s集群提供持久化)并回车#" --inputbox "请检查IP是否一致,确定提交?" 10 100 "$IP" 3>&1 1>&2 2>&3)
                         echo  $NFS_IP > /root/K8s/nfs_ip.txt
                         #导入db节点ip到ansible
                        grep   '\[nfs\]'  /etc/ansible/hosts || echo $NFS_IP |sed  '1 i\[nfs]'    >> /etc/ansible/hosts 
                        ;;

                        #启用k8s集群 Glustgfs分布式存储持久化方案
                        2)  
                        #指定存储节点ip
                        _db_ip

                        ;;
                        *) echo "操作错误"
                        ;;
                    esac
                
            else
                clear
fi
}
#################################################################################################

_menu_A (){
OPTION=$(whiptail --title "K8s,  Vision @ 2019" --menu "Choose your option" 20 65 13 \
"1" "Single K8s One-click" \
"2" "Cluste K8s One-click" \
"3" "Cluste K8s add node" \
"4" "Single K8s add node" \
"5" "del node" \
"6" "Uninstall K8s" \
"7" "Quit"  3>&1 1>&2 2>&3)
exitstatus=$?
if [ $exitstatus = 0 ]
            then
                    case $OPTION in
                      1)
                      password_=$(whiptail --title "#请输入本机root密码 并回车#" --passwordbox "确定提交?" 10 60 3>&1 1>&2 2>&3)
                          #部署单机版ansible   
                        .  /root/K8s/shell_01/Single_ansible.sh
                        _single_ansible 
                       sh +x     /root/K8s/Cluster_shell_yaml/k8s-init.sh
                       sh  +x      /root/K8s/single_shell/Single_init_v2.0.sh
                       echo  "安装k8s,Wed界面dashboard,端口号42345"
                       sh  +x       /root/K8s/single_shell/dashboard.sh  
                       #开dns

                       whiptail --title "kubernetes_v1.19.5单机版安装完毕" --msgbox "K8s单机版安装完毕,web控制界面dashboard地址为： http://IP:42345 \n内网yum网址为:http://IP:42344  \
                             \n  集群grafan监控地址为http://IP:30000  ,默认账户密码admin admin \n \nk8s默认nfs持久化路径为： /data/nfs \n    \
                             \n \n如有疑问请加QQ群893480182" 20 110

                       clear
source   /root/.bash_profile
kubectl  get csr
 kubectl  get cs
 kubectl  get node
 #服务状态检测
 sh /root/K8s/shell_01/Check02.sh
                       
                        ;;  
                        2) 
                            _yumrepo
                            _Cluste_jiqun_One_click   #集群初始化环境
                            _Cluste_K8s_One_click     #k8s集群部署
                                                   echo  "安装k8s,Wed界面dashboard,端口号42345"
                          # sh  +x       /root/K8s/single_shell/dashboard_Cluster.sh
                          #  /usr/local/bin/kubectl  -s http://${IP}:8080    apply -f /root/K8s/k8s_yaml/coredns/coredns.yaml
                         #若配置了db
                        [[ $var_c1  =  0 ]]  && {
                         sh  /root/K8s/glusterfs/glusterfs_chek.sh &&  sh  /root/K8s/glusterfs/db_fdisk.sh && sh /root/K8s/glusterfs/glusterfs_install_rpm.sh; sleep 5; _k8s_prometheus; _k8s_grafan #k8s prometheus环境  #k8s grafan环境
                         file_path='/data/nfs/k8s'
                         name_01=NFS
                         #设置默认动态存储
                          kubectl patch storageclass gluster-heketi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
                        }
                        [[ $var_c1  =  0 ]]  || {
                         sh /root/K8s/nfs/Cluster_nfs/nfs_client_01.sh;_k8s_prometheus; _k8s_grafan #k8s prometheus环境  #k8s grafan环境
                         file_path='/data/nfs/k8s'
                         #设置默认动态存储
                          kubectl patch storageclass gluster-heketi -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'
                        }
                            # [ $?  -ne 0 ] && echo "k8s集群部署完毕，持久化部署条件不满足，k8s集群持久化部署失败"
                             whiptail --title "kubernetes_v1.19.5集群版安装完毕" --msgbox "K8s集群版安装完毕,web控制界面dashboard地址为： http://IP:42345 \n内网yum网址为:http://IP:42344  \
                             \n  集群grafan监控地址为http://IP:30000  ,默认账户密码admin admin [注意:如果没有开启k8s数据持久化功能(或者持久化功能启用失败),请无视此条提示]
                             \n \nk8s默认glusterfs分布式集群持久化 \n glusterfs分布式存储如下 \n $( cat /root/K8s/ip_db.txt|xargs)   \
                             \n \nk8s默认NFS存储持久化路径为： ${file_path} \n NFS存储节点如下 \n ${NFS_IP}   \
                             \n \n如有疑问请加QQ群893480182" 20 110
                             clear
                            source   /root/.bash_profile
                   sh  +x         /root/K8s/shell_01/Check02.sh
                            # ansible  db -m shell -a  "df -h |  grep k8s_data"

 #修复授权

                        ;;
                        3) 
                          
                          sh  +x  /root/K8s/shell_01/node_add_ssh_key_01.sh   ||  exit 1   
                           . /root/K8s/ip_3.txt
                           echo  "hi 兄弟 这里并没有卡死，耐心等待即可"
                          sh  +x   /root/K8s/shell_01/node_add_02.sh  ||  exit 1
                          ansible  slave  -m shell  -a  "sh  /tmp/add_node_init_03.sh"
                           ansible  slave  -m shell  -a  " rm -f /tmp/add_node_init_03.sh"
                          #授权
                          CSRS=$(/usr/local/bin/kubectl get csr | awk '{if(NR>1) print $1}')
                               for csr in $CSRS;
                               do
                                   /usr/local/bin/kubectl certificate approve $csr;
                               done
                               sleep 5
                               for var_3  in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt)
                                  do 
                                    /usr/local/bin/kubectl label node ${var_3}  node-role.kubernetes.io/node='node'
                                done
                          /usr/local/bin/kubectl get node
                          /usr/local/bin/kubectl get cs

                        ;;                        
                        4)  
                          sh  +x  /root/K8s/shell_01/Single_node_add_ssh_key_01.sh   ||  exit 1   
                           . /root/K8s/ip_3.txt
                           echo  "hi 兄弟 这里并没有卡死，耐心等待即可"
                          sh  +x   /root/K8s/shell_01/node_add_02.sh  ||  exit 1
                          ansible  slave  -m shell  -a  "sh  /tmp/add_node_init_03.sh"
                           ansible  slave  -m shell  -a  " rm -f /tmp/add_node_init_03.sh"
                          #授权
                          CSRS=$(/usr/local/bin/kubectl get csr | awk '{if(NR>1) print $1}')
                               for csr in $CSRS;
                               do
                                   /usr/local/bin/kubectl  -s http://${IP}:8080  certificate approve $csr;
                               done
                               sleep 5
                               for var_3  in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt)
                                  do 
                                    /usr/local/bin/kubectl -s http://${IP}:8080  label node ${var_3}  node-role.kubernetes.io/node='node'
                                done
                          /usr/local/bin/kubectl -s http://${IP}:8080  get node
                          /usr/local/bin/kubectl  -s http://${IP}:8080  get cs

                        ;;
                        5)  
                         sh  +x  /root/K8s/shell_01/node_del.sh

                        ;;
                        6)  
                        if (whiptail --title "强制卸载k8s所有环境清除所有数据,此操作不可恢复" --yesno "此操作不可逆,会清空数据分区,请慎重操作！" 10 60) then
                            echo "You chose Yes. Exit status was $?."
                            sh +x /root/K8s/Uninstall/rm_copy_install.sh
                            sleep 1
                            whiptail --title "卸载完毕重启生效" --msgbox "卸载完毕请务必立即重启已卸载的所有节点服务器！！" 10 60
                            clear 
                            exit 0
                        else
                            echo "You chose No. Exit status was $?."
                            
                        fi
                        
                        ;;

                        7)  
                            clear 
                            exit 0
                        ;;
                        *) echo "操作错误"
                        ;;
                    esac
                
            else
                clear
fi
}
################################################################################
