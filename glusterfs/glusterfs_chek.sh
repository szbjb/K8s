#!/bin/bash
#ansible_主机处理master执行
sed '/^\s*$/d'  /etc/ansible/hosts  | grep  "^#"   -v  > /tmp/ansible_hosts.log
cat  /tmp/ansible_hosts.log >   /etc/ansible/hosts
#
#输入db集群ip
#获取db集群ip
sed '/^\s*$/d'   /tmp/db_ip.txt | grep  "^#"   -v > /root/K8s/ip_db.txt
db_num=$(wc -l /root/K8s/ip_db.txt|awk '{print $1}')
[ $db_num  -lt  2 ]   && {
echo  "存储数量低于2台，分布式存储部署终止glusterfs"
exit 1
}

#检测存储集群网络连通性
ansible db  -m ping||{
echo "存储集群通讯异常"
echo "部署终止"
}
#db主机名源修改
ansible db -m shell -a "hostname"|xargs  -n 1  |egrep   -v  "CHANGED|rc|>|\|" |xargs  -n 2 > /root/K8s/ip_db01.txt
sed  "s/$/-db/" /root/K8s/ip_db01.txt  > /root/K8s/ip_db02.txt   && sed  's/ / hostname=/g' /root/K8s/ip_db02.txt   -i
awk '{print $0" "FNR}' /root/K8s/ip_db02.txt|sed 's/db /db/g'  > /root/K8s/ip_db03.txt 
sed  '1 i\[db]'  /root/K8s/ip_db03.txt  -i
cat >/root/K8s/shell_01/name.yaml<<EOF
---
- hosts: db
  remote_user: root
  tasks:
     - name: change name
       raw: "echo {{hostname|quote}} > /etc/hostname"
     - name:
       shell: hostname {{hostname|quote}}
EOF
ansible-playbook  -i   /root/K8s/ip_db03.txt    /root/K8s/shell_01/name.yaml