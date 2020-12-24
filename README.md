QQ交流群  微信交流群
====
![template.png](https://i.loli.net/2019/10/10/FhPgymjwpKSHEC3.png)

### 重点集群配置推荐,太低会导致安装异常
**



- - node节点最低4gb
- - Master节点最低8gb**


* Q群名称：K8s自动化部署交流
* Q群   号：893480182
### - 实测单机版支持腾讯云服务器
### - 实测集群版支持天翼云服务器
### - 实测集群版支持阿里云服务器(需要预先设置中文字符集否则菜单界面乱码不显示中文，后续我会修复这个问题到脚本里面 暂时没有阿里云服务器调试)


特点: 完全离线，不依赖互联网(系统新装配置好ip开机即可！其他都什么都不用安装)
====
1. 基于内核高可用api-server,
1. 真正原生centos7.3.-7.6Minimal新装系统(只需要统一集群的root密码即可)一键搭建k8s集群
1. 单机/集群任意服务器数量一键安装(目前一个节点对应一个etcd节点后续会分离可自定义)
1. 一键批量增删node节点(新增的服务器系统环境必须干净密码统一)
1. ipvs负载均衡,内网yum源共享页面端口42344
1. 单机版或集群版默认集成prometheus+grafan监控环境,默认端口30000,账号密码admin admin
1. 图形化向导菜单安装,web管理页面dashboar端口42345
1. Heketi+GlusterFS（分布式存储集群）+helm完全一键离线部署
1. 默认版本v1.19.5,可执行替换各版本软件包,集群版目前已测安装数量在1-30台一键安装正常
1. 集群数量超过4台及以上默认开启k8s数据持久化方案:glusterfs+Heketi 最低3台分布式存储 \n (全自动自动安装,启用k8s集群持久化方案务必保证存储节点均有一块空盘(例如/deb/sdb无需分区(默认40%用于k8s集群持久化60%挂载到本机的/data目录)))
如启用Heketi+GlusterFS，默认会创建一个pvc验证动态存储效果



一键安装
===
#### 一键安装介绍任选通道进行安装
一键安装命令(要求centos7系统为新装系统无任何软件环境可联网)
不推荐git下来仓库大概1.5gb左右比较大，可以直接下载离线包
##一键安装通道01(默认走家庭宽带普通通道---不稳定不推荐)
``` shell
while [ true ]; do  rm -f K8s_1.4.0.tar*;curl  -o   K8s_1.4.0.tar  http://www.linuxtools.cn:42344/K8s_1.4.0.tar && break 1 ||sleep 5;echo 网络错误正在重试下载 ;done && tar -xzvf  K8s_1.4.0.tar && cd K8s/ && sh install.sh
```

##一键安装通道02(走群友无私赞助电信机房专线服务器--高速稳定下载----强烈推荐)

``` shell
while [ true ]; do  rm -f K8s_1.4.0.tar*;curl  -o   K8s_1.4.0.tar  http://www.linuxtools.cn:42344/K8s_1.4.0.tar && break 1 ||sleep 5;echo 网络错误正在重试下载 ;done && tar -xzvf  K8s_1.4.0.tar && cd K8s/ && sh install.sh
```

```
[root@k8s-master-db2 ~]#
[root@mubanji49 ~]# sh K8s/shell_01/Check02.sh
==============master节点健康检测 kube-apiserver  kube-controller-manager   kube-scheduler  etcd  kubelet kube-proxy docker==================
192.168.123.69 | CHANGED | rc=0 >>
active active active active active active active

===============================================note节点监控检测 etcd  kubelet kube-proxy docker===============================================
192.168.123.25 | CHANGED | rc=0 >>
active active active active

192.168.123.23 | CHANGED | rc=0 >>
active active active active

192.168.123.24 | CHANGED | rc=0 >>
active active active active

192.168.123.22 | CHANGED | rc=0 >>
active active active active

===============================================监测csr,cs,pvc,pv,storageclasses===============================================
NAME                                                                                                 AGE     REQUESTOR           CONDITION
certificatesigningrequest.certificates.k8s.io/node-csr-BhGxRilO9l04KxPRB8xvyyLfJWXbj9uBWaeSKz3PoB4   3m1s    kubelet-bootstrap   Approved,Issued
certificatesigningrequest.certificates.k8s.io/node-csr-Fp2t03YNTTPFKQf_ljIZvuYAGOyuv3SbJ97Dhm5DIzQ   2m59s   kubelet-bootstrap   Approved,Issued
certificatesigningrequest.certificates.k8s.io/node-csr-RapTjQ_XBKSG8vrNX8_WO8szy39WE5hUN8lXMIHCIZM   2m59s   kubelet-bootstrap   Approved,Issued
certificatesigningrequest.certificates.k8s.io/node-csr-eMBnkUV4nUFXDhxTXiCc7ZjpkBL6UhRf56N_qpVMnVM   2m59s   kubelet-bootstrap   Approved,Issued
certificatesigningrequest.certificates.k8s.io/node-csr-uVc1At65pHTwPmRTEZ584h2AWnGeopEfaKSuu-pbi7I   2m59s   kubelet-bootstrap   Approved,Issued

NAME                                 STATUS    MESSAGE             ERROR
componentstatus/scheduler            Healthy   ok
componentstatus/controller-manager   Healthy   ok
componentstatus/etcd-3               Healthy   {"health":"true"}
componentstatus/etcd-2               Healthy   {"health":"true"}
componentstatus/etcd-0               Healthy   {"health":"true"}
componentstatus/etcd-1               Healthy   {"health":"true"}
componentstatus/etcd-4               Healthy   {"health":"true"}

NAME                                  STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS     AGE
persistentvolumeclaim/gluster1-test   Bound    pvc-c02684ba-ff23-11e9-ae0a-000c29ed75cf   1Gi        RWX            gluster-heketi   50s
persistentvolumeclaim/my-grafana      Bound    pvc-c5734aaf-ff23-11e9-ae0a-000c29ed75cf   10Gi       RWO            gluster-heketi   41s

NAME                                                        CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM                   STORAGECLASS     REASON   AGE
persistentvolume/pvc-c02684ba-ff23-11e9-ae0a-000c29ed75cf   1Gi        RWX            Delete           Bound    default/gluster1-test   gluster-heketi            45s
persistentvolume/pvc-c5734aaf-ff23-11e9-ae0a-000c29ed75cf   10Gi       RWO            Delete           Bound    default/my-grafana      gluster-heketi            23s

NAME                                         PROVISIONER               AGE
storageclass.storage.k8s.io/gluster-heketi   kubernetes.io/glusterfs   50s
===============================================监测node节点labels===============================================
NAME             STATUS   ROLES    AGE     VERSION   LABELS
192.168.123.22   Ready    node     2m38s   v1.19.5   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=192.168.123.22,kubernetes.io/os=linux,node-role.kubernetes.io/node=node,storagenode=glusterfs
192.168.123.23   Ready    node     2m37s   v1.19.5   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=192.168.123.23,kubernetes.io/os=linux,node-role.kubernetes.io/node=node,storagenode=glusterfs
192.168.123.24   Ready    node     2m38s   v1.19.5   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=192.168.123.24,kubernetes.io/os=linux,node-role.kubernetes.io/node=node,storagenode=glusterfs
192.168.123.25   Ready    node     2m37s   v1.19.5   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,kubernetes.io/arch=amd64,kubernetes.io/hostname=192.168.123.25,kubernetes.io/os=linux,node-role.kubernetes.io/node=node,storagenode=glusterfs
192.168.123.69   Ready    master   2m38s   v1.19.5   beta.kubernetes.io/arch=amd64,beta.kubernetes.io/os=linux,dashboard=master,kubernetes.io/arch=amd64,kubernetes.io/hostname=192.168.123.69,kubernetes.io/os=linux,node-role.kubernetes.io/master=master,storagenode=glusterfs
===============================================监测coredns是否正常工作===============================================
coredns-57656b67bb-nzzlw              1/1     Running   0          2m15s
Server:    10.0.0.2
Address 1: 10.0.0.2 kube-dns.kube-system.svc.cluster.local

Name:      kubernetes
Address 1: 10.0.0.1 kubernetes.default.svc.cluster.local
pod "dns-test" deleted
===============================================监测,pods状态===============================================
NAMESPACE     NAME                                  READY   STATUS    RESTARTS   AGE     IP            NODE             NOMINATED NODE   READINESS GATES
default       my-grafana-766fb5978b-tq6l8           0/1     Running   0          43s     172.17.1.3    192.168.123.69   <none>           <none>
kube-system   coredns-57656b67bb-nzzlw              1/1     Running   0          2m17s   172.17.23.2   192.168.123.24   <none>           <none>
kube-system   kubernetes-dashboard-5b5697d4-khqqd   1/1     Running   0          2m14s   172.17.1.2    192.168.123.69   <none>           <none>
kube-system   tiller-deploy-7dd4495c74-nzz74        1/1     Running   0          2m33s   172.17.14.2   192.168.123.22   <none>           <none>
===============================================监测node节点状态===============================================
NAME             STATUS   ROLES    AGE     VERSION   INTERNAL-IP      EXTERNAL-IP   OS-IMAGE                KERNEL-VERSION          CONTAINER-RUNTIME
192.168.123.22   Ready    node     2m40s   v1.19.5   192.168.123.22   <none>        CentOS Linux 7 (Core)   3.10.0-514.el7.x86_64   docker://19.3.4
192.168.123.23   Ready    node     2m39s   v1.19.5   192.168.123.23   <none>        CentOS Linux 7 (Core)   3.10.0-514.el7.x86_64   docker://19.3.4
192.168.123.24   Ready    node     2m40s   v1.19.5   192.168.123.24   <none>        CentOS Linux 7 (Core)   3.10.0-693.el7.x86_64   docker://19.3.4
192.168.123.25   Ready    node     2m39s   v1.19.5   192.168.123.25   <none>        CentOS Linux 7 (Core)   3.10.0-693.el7.x86_64   docker://19.3.4
192.168.123.69   Ready    master   2m40s   v1.19.5   192.168.123.69   <none>        CentOS Linux 7 (Core)   3.10.0-957.el7.x86_64   docker://19.3.4
================================================监测helm版本================================================
Client: &version.Version{SemVer:"v2.15.2", GitCommit:"8dce272473e5f2a7bf58ce79bb5c3691db54c96b", GitTreeState:"clean"}
Server: &version.Version{SemVer:"v2.15.2", GitCommit:"8dce272473e5f2a7bf58ce79bb5c3691db54c96b", GitTreeState:"clean"}
[root@mubanji49 ~]#
[root@mubanji49 ~]# ansible all -m shell -a  "cat /etc/redhat-release "
192.168.123.23 | CHANGED | rc=0 >>
CentOS Linux release 7.3.1611 (Core)

192.168.123.22 | CHANGED | rc=0 >>
CentOS Linux release 7.3.1611 (Core)

192.168.123.24 | CHANGED | rc=0 >>
CentOS Linux release 7.4.1708 (Core)

192.168.123.25 | CHANGED | rc=0 >>
CentOS Linux release 7.4.1708 (Core)

192.168.123.69 | CHANGED | rc=0 >>
CentOS Linux release 7.6.1810 (Core)

[root@mubanji49 ~]#


```



*  ps:目前是单master,后期会上多master高可用
*  ps:近期提交代码过于频繁有时候可能会有=一些bug,欢迎到群随时提出



====
### [高能警告] 系统只能存在一个固定ip地址 一个网卡一个ip 切记美分系统不能多个ip多个网卡
### [高能警告] 暂仅支持centos7.3-centos7.7， “不支持Centos7.2及其以下版本”
### [高能警告] 系统ip不能使用 10.0.0.0网段,尽量避开系统使用172.17.x.x  10.0.0.x网段(否则安装会有问题)


** 
# K8s升级替换v1.14.0   v1.15.0
#如果不需要使用v1.14.0  v1.15.0直接默认一键安装即可。master分支默认的是v1.19.5
## 默认版本为v1.19.5,提供升级软件包v14  v15自行下载后放到  K8s/Software_package  目录即可(务必删除原有的)
链接：[http://linuxtools.cn:42344/K8s_list/](http://linuxtools.cn:42344/K8s_list/)


放入前务必执行以下操作
``` shell
rm -fv  K8s/Software_package/kubernetes-server-linux-amd64.tar.a*
```

``` shell
#可选执行-----替换第三方yum源
rm  -fv  rm -f /etc/yum.repos.d/*
while  [ true ]; do  curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo   && break  1   ;done
while  [ true ]; do  curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo   && break  1   ;done
```


华丽分界线。。。。。。。。。。。。。。


一键安装
===
#### 一键安装介绍任选通道进行安装
一键安装命令(要求centos7系统为新装系统无任何软件环境可联网)
不推荐git下来仓库大概1.5gb左右比较大，可以直接下载离线包


##一键安装通道01(走私有服务器高速通道)
``` shell
while [ true ]; do  rm -f K8s_1.4.0.tar*;curl  -o   K8s_1.4.0.tar  http://www.linuxtools.cn:42344/K8s_1.4.0.tar && break 1 ||sleep 5;echo 网络错误正在重试下载 ;done && tar -xzvf  K8s_1.4.0.tar && cd K8s/ && sh install.sh
```

##一键安装通道02(走码云服务器)

``` shell
#零时弃用
```

视频演示地址
===
https://www.bilibili.com/video/av57242055?from=search&seid=4003077921686184728


#### 测试环境
* VMware15虚拟化平台，所有服务器节点2核2G
* 已测1-50节点安装正常
* 建议新装centos7.6系统,环境干净(不需要提前安装任何软件不需要提前安装docker).集群功能至少2台服务器节点


网络  | 系统  | 内核版本 | IP获取方式 | docker版本 | Kubernetes版本 |K8s集群安装方式 |
---- | ----- | ------  | ---- |  ---- | ---- | ---- |
桥接模式  | 新装CentOS7.6.1810 (Core) | 3.10.0-957.el7.x86_64 | 手动设置固定IP(不能dhcp获取所有节点) | 18.06.1-ce | v1.19.5  | 二进制包安装  |



#### 安装教程
``` shell
rm -f K8s_1.4.0.tar*
```

#下载通道01 走普通家庭宽带下载点
``` shell
curl  -o   K8s_1.4.0.tar  http://www.linuxtools.cn:42344/K8s_1.4.0.tar
```

#下载通道02 走群友无私赞助电信机房专线服务器--高速稳定下载----强烈推荐
``` shell
curl  -o   K8s_1.4.0.tar  http://www.linuxtools.cn:42344/K8s_1.4.0.tar
```

``` shell
tar -xzvf  K8s_1.4.0.tar
cd K8s/ && sh install.sh
```
#### 使用说明

1. xxxx
2. xxxx
3. xxxx

#### 参与贡献


#### 使用截图
![QQ图片20190930164529.png](https://i.loli.net/2019/10/10/HSEse5NOjkg8FKy.png)
![2.png](https://i.loli.net/2019/10/10/MijocxtWpvQPOsz.png)
![4.png](https://i.loli.net/2019/10/10/tbVETWwZGJA3rmz.png)
![6.png](https://i.loli.net/2019/10/10/v3eKdf87wspmJg5.png)
![5.png](https://i.loli.net/2019/10/10/GlsO9At5YEckKFB.png)
![9.png](https://i.loli.net/2019/10/10/KSIAqo9xwWYZL3V.png)
![8.png](https://i.loli.net/2019/10/10/XGvfu2k4BiDWrAb.png)
![1.png](https://i.loli.net/2019/10/10/S4CE5k2LHoMAwUd.png)
![3.png](https://i.loli.net/2019/10/10/FcwyW9CiuEnLZsK.png)
![7.png](https://i.loli.net/2019/10/10/8dvlNRK9njxDSHr.png)
![QQ图片20190930164536.png](https://i.loli.net/2019/10/10/DO5loM7L6ruafEP.png)
![QQ图片20190930164546.png](https://i.loli.net/2019/10/10/FukwDrqNHXERo2n.png)

监控图片一揽
===
![QQ截图20200208133429.png](https://i.loli.net/2020/02/08/4yrWXKaL8lpe6PI.png)
![pod监控.png](https://i.loli.net/2019/09/30/hVHgSbNuysn4oY7.png)
![QQ图片20190930163116.png](https://i.loli.net/2019/09/30/kJOxmhYXPBrjL7s.png)
![QQ图片20190930163124.png](https://i.loli.net/2019/09/30/nGRTNkvDeidHZ8b.png)
![QQ图片20190930163136.jpg](https://i.loli.net/2019/09/30/AgICwTmPjVLzDWX.jpg)
![QQ图片20190930163127.png](https://i.loli.net/2019/09/30/sfCO2k5enMSwIh6.png)
![QQ图片20190930163130.png](https://i.loli.net/2019/09/30/n18jgbzTDpUdfmY.png)
![QQ图片20190930163133.png](https://i.loli.net/2019/09/30/p9hJu5Bv14sdZUC.png)

 
 Dashboard图片
 ===
![QQ截图20190930163923.png](https://i.loli.net/2019/09/30/edQrFAPov48nub2.png)
![QQ截图20190930164028.png](https://i.loli.net/2019/09/30/sNRm6CUoXJ4y1Bp.png)
![QQ截图20190930163252.png](https://i.loli.net/2019/09/30/IksfRAZbCwgnl7F.png)
![QQ截图20190930163943.png](https://i.loli.net/2019/09/30/O5oSg3yKT7mB1Wj.png)
![QQ截图20190930164058.png](https://i.loli.net/2019/09/30/8bVKGEvJXFgxoun.png)
![QQ截图20190930164008.png](https://i.loli.net/2019/09/30/1p5glKyUbSimIZc.png)
![QQ截图20190930164000.png](https://i.loli.net/2019/09/30/kXadozpYbsMvKun.png)


更新日志

===
### -----------------
2020-12-25
默认k8s版本v1.19.5 纯二进制部署 非kubeadm
升级所有二进制相关组件
cfssl-certinfo_1.5.0_linux_amd64
cfssl_1.5.0_linux_amd64
cfssljson_1.5.0_linux_amd64
etcd-v3.4.14-linux-amd64.tar.gz
flannel-v0.13.0-linux-amd64.tar.gz
heketi-v10.1.0.linux.amd64.tar.gz
helm-v3.4.2-linux-amd64.tar.gz
v1.19.5_kubernetes-server-linux-amd64.tar.gz
完善多master高可用,基于ipvs
修复若干bug。。。线上环境已使用

===
### -----------------
2020-4-21
新增多master高可用,基于ipvs(仅供测试使用目前还没有深入测试过可能会有bug)

修复一些bug

### -----------------
===
### -----------------
2020-2-8
新增卸载功能,优化部署脚本

修复一些bug+内核优化

### -----------------
### -----------------
2019-10-19

修复一些bug+内核优化

### -----------------
### -----------------


2019-10-10

修复时区问题,所有pod默认中国上海时区

### -----------------
### -----------------


2019-9-16

1. 集群版新增prometheus  +grafan集群监控环境(被监控端根据集群数量自动弹性扩展)  默认端口30000，默认账户密码admin admin
1. 必须在启用数据持久化功能的基础上才会开启
1. grafana已内置了k8s集群pod监控模板,集群基础信息监控模板,已内置饼图插件，开箱即可用
### -----------------


2019-9-27

1. 单机版新增nfs_k8s动态存储,单机版k8s也能愉快的玩helm了,后续增加集群版nfs云端存储/本地存储持久化方案。
1. 单机版新增prometheus+grafan监控环境
1. 单机版默认storageclasses均为gluster-heketi

### -----------------
### -----------------


2019-9-25

1. 优化一些参数,集群版持久化功能支持最低2个节点起
1. 单机版新增helm
1. 修复一些bug

### -----------------

2019-9-13

1. 集群版新增coredns 感谢群内dockercore大佬的指导
1. 优化集群版部署脚本,新增集群重要功能监测脚本
1. 新增内置busybox镜像测试dns功能

### -----------------

2019-8-26
1 新增node节点批量增删
2 新增glusterfs分布式复制卷---持久化存储(集群版4台及以上自动内置部署)

### -----------------



2019-7-11
修复部分环境IP取值不精确导致etcd安装失败的问题

### -----------------
2019-7-10

1. 新增集群版 web图形化控制台dashboard
2. 更新docker-ce版本为 Version: 18.09.7
K8s集群版安装完毕,web控制界面dashboard地址为                           http://IP:42345

### -----------------
2019-7-1

新增单机版 web图形化控制台dashboard
K8s单机版安装完毕,web控制界面dashboard地址为                           http://IP:42345