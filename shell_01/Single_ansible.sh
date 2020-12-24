#!/bin/bash
#单机版创建ansible免交互环境
_single_ansible  ()  {
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))
# password_=$(whiptail --title "#请输入新增Node节点服务器统一的root密码 并回车#" --passwordbox "请确认所有节点(含本机)root密码一致,确定提交?" 10 60 3>&1 1>&2 2>&3)
#
master_hosts_=$IP
#ansible环境配置
yum install ansible   libselinux-python   sshpass   -y   >   /dev/null
#ansible调优
sed  s/'#host_key_checking = False'/'host_key_checking = False'/g   /etc/ansible/ansible.cfg  -i
sed  s/'#pipelining = False'/'pipelining = True'/g   /etc/ansible/ansible.cfg  -i
sed      '/^GSSAPI/s/yes/no/g;  /UseDNS/d; /Protocol/aUseDNS no'    /etc/ssh/sshd_config   -i
echo  'gather_facts: nogather_facts: no' >> /etc/ansible/ansible.cfg
systemctl restart  sshd
#清除本地ssh环境
\rm -f ~/.ssh/*
#创建秘钥对
ssh-keygen -t dsa -f /root/.ssh/id_dsa -N  ""  # &>/dev/null

#配置免交互登录
ssh-keygen   -R  $IP 2>/dev/null
sshpass   -p  "$password_"  ssh-copy-id   -i  /root/.ssh/id_dsa.pub   root@$IP   -o StrictHostKeyChecking=no 
###配置ansible hosts文件
grep   master /etc/ansible/hosts  || {
cat >>/etc/ansible/hosts<<EOF
[master]
$IP

[slave]

[all]
$IP

[dfs1]
$IP

[gpu]
$IP

[db]
$IP

EOF
} 
}


