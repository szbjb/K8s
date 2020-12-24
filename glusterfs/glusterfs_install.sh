#!/bin/bash
# 先安装 gluster 源
yum install centos-release-gluster -y

# 安装 glusterfs 组件
yum install -y glusterfs glusterfs-server glusterfs-fuse glusterfs-rdma glusterfs-geo-replication glusterfs-devel

##创建 glusterfs 目录
mkdir /opt/glusterd

# 修改 glusterd 目录
sed -i 's/var\/lib/opt/g' /etc/glusterfs/glusterd.vol

# 启动 glusterfs
systemctl start glusterd.service

# 设置开机启动
systemctl enable glusterd.service

#查看状态
systemctl status glusterd.service



#创建共享劵
mkdir /opt/gfs_data

#  添加节点到 集群 执行操作的本机不需要probe 本机
gluster peer probe 192.168.2.204

# 查看集群状态
gluster peer status