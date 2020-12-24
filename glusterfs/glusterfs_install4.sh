#!/bin/bash
#ansible_主机处理master执行
sed '/^\s*$/d'  /etc/ansible/hosts  | grep  "^#"   -v  > /tmp/ansible_hosts.log
cat  /tmp/ansible_hosts.log >   /etc/ansible/hosts
#
#输入db集群ip
#获取db集群ip
sed '/^\s*$/d'   /tmp/db_ip.txt | grep  "^#"   -v > /root/K8s/ip_db.txt
db_num=$(wc -l /root/K8s/ip_db.txt|awk '{print $1}')
[ $db_num  -ge  4 ]   || {
echo  "存储数量低于4台，分布式存储部署终止glusterfs"
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



###选择一台主机默认db1执行主操作
db1=$(ansible db -m shell -a "hostname"|xargs  -n 1  |egrep   -v  "CHANGED|rc|>|\|" |xargs  -n 2| grep db1|awk  '{print $1}')
db2=$(ansible db -m shell -a "hostname"|xargs  -n 1  |egrep   -v  "CHANGED|rc|>|\|" |xargs  -n 2| grep db2|awk  '{print $1}')
db3=$(ansible db -m shell -a "hostname"|xargs  -n 1  |egrep   -v  "CHANGED|rc|>|\|" |xargs  -n 2| grep db3|awk  '{print $1}')
db4=$(ansible db -m shell -a "hostname"|xargs  -n 1  |egrep   -v  "CHANGED|rc|>|\|" |xargs  -n 2| grep db4|awk  '{print $1}')

#所有db主机执行
ansible db -m shell -a "yum install -y glusterfs glusterfs-server expect glusterfs-cli glusterfs-fuse glusterfs-rdma glusterfs-geo-replication glusterfs-devel"
ansible db -m shell -a "systemctl restart glusterd.service"
ansible db -m shell -a "systemctl enable  glusterd.service"
ansible db -m shell -a "systemctl is-active glusterd.service"
ansible db -m shell -a "glusterfs -V"
#glusterd安装结束#所有节点执行
fdisk  -l | grep '\/dev\/sd'
clear
ansible db -m shell -a "mkdir -pv /data/glusterfs_brick{1..3}"
ansible db -m shell -a " mkdir  -pv  /data/k8s_data"
#加入信任主机
ansible $db1 -m shell -a "gluster peer probe $db2"
ansible $db1 -m shell -a "gluster peer probe $db3"
ansible $db1 -m shell -a "gluster peer probe $db4"
ansible $db1 -m shell -a "gluster peer status"

##配置复制卷 123.80其中一台执行
ansible $db1 -m shell -a "gluster volume create gv2 replica 2 $db1:/data/glusterfs_brick2 $db2:/data/glusterfs_brick2  force"
ansible $db1 -m shell -a "gluster volume start gv2 "  #启动gv2卷
ansible $db1 -m shell -a "gluster volume info gv2   "  #查看gv2信息
ansible db  -m shell -a "mount -t glusterfs 127.0.0.1:/gv2 /data/k8s_data"
ansible db -m shell -a "df -h|grep gv2"
#测试
ansible $db1 -m shell -a "cd  /data/k8s_data;touch test{1..6}"

ls  -l /data/glusterfs_brick2
##所有节点执行(对比是否有两台有数据)
ls  -l /data/glusterfs_brick2
#配置分布式复制卷
cat > /root/K8s/glusterfs/stop.sh  << 'EOH'
/usr/bin/expect << EOF
spawn /usr/sbin/gluster volume stop gv2
expect {
        "Stopping" {send "y\r";}       
}
expect eof 
EOF
EOH
scp  /root/K8s/glusterfs/stop.sh  $db1:/tmp
ansible $db1 -m shell -a "sh /tmp/stop.sh"
ansible $db1 -m shell -a "gluster volume add-brick gv2 replica 2 $db3:/data/glusterfs_brick1 $db4:/data/glusterfs_brick1 force " #添加brick到gv2中
ansible $db1 -m shell -a "gluster volume start gv2 "
ansible $db1 -m shell -a "gluster volume info gv2 "
ansible $db1 -m shell -a "gluster peer status"
##扩展为分布式复制卷后平衡存储  
ansible $db1 -m shell -a "gluster volume rebalance gv2 start"
#检查分布式存储挂载情况
ansible  db -m shell -a  "df -h |  grep k8s_data"
#
#调优
# # 开启 指定 volume 的配额
# gluster volume quota gv2 enable

# # 限制 指定 volume 的配额
# gluster volume quota gv2 limit-usage / 1TB

# 设置 cache 大小, 默认32MB
#gluster volume set gv2 performance.cache-size 1GB

# # 设置 io 线程, 太大会导致进程崩溃
ansible $db1 -m shell -a "gluster volume set gv2 performance.io-thread-count 16"

# # 设置 网络检测时间, 默认42s
ansible $db1 -m shell -a "gluster volume set gv2 network.ping-timeout 10"

# # 设置 写缓冲区的大小, 默认1M
ansible $db1 -m shell -a "gluster volume set gv2 performance.write-behind-window-size 1024MB"

#4节点分布式复制卷安装结束
echo  "k8s默认持久化路径为/data/k8s_data"
echo   "/data/glusterfs_brick1"
