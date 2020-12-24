#!/bin/bash
#创建ansible免交互环境
#获取新增note集群ip
_cluster_ip  ()  {
if (whiptail --title "导入集群新增node节点IP地址(单机版暂时不支持node扩展)" --yes-button "YES" --no-button "NO"  --yesno "批量导入集群IP地址?" 10 80) then
    echo "You chose Skittles Exit status was $?."
    echo  ok
    rm -f   /root/K8s/.ip.txt*
    rm -f   /root/K8s/ip.txt
    > /root/K8s/ip.txt
cat >  /root/K8s/ip.txt <<EOF
#按下字母i键进入编辑模式,将ip批量粘贴进来即可
#首次使用此脚本安装集群数量至少2台及以上才能使用此功能
#单机版不能使用此方法一键添加node节点
#格式如下(不包含#号,不能有空行,仅填写需要新增的note节点ip即可),导入完毕后wq! / x! 退出即可继续后面的操作
#x.x.x.x
#x.x.x.x
#x.x.x.x
EOF
    vi /root/K8s/ip.txt
    echo  IP导入完毕
else
    echo "中断操作"
    echo  no
    exit 1
fi
}

_cluster_ip
password_=$(whiptail --title "#请输入新增Node节点服务器统一的root密码 并回车#" --passwordbox "请确认所有节点root密码一致,确定提交?" 10 60 3>&1 1>&2 2>&3)

#批处理ip.txt
master_hosts_=$( grep  master  /root/K8s/ip_2.txt |awk   -F  "="   '{print  $NF}')
[  ! $master_hosts_ ] &&  {
echo 当前环境为单机版.单etcd节点扩容为多node节点
rpm -aq | grep net-tools   ||  yum install net-tools -y  >   /dev/null
#检测本机master IP地址
master_hosts_=$(ifconfig | grep netmask |egrep  -v   "172.17|127.0.0.1" |awk  '{print  $2}')
}
grep -v  "^#" /root/K8s/ip.txt | awk '{for(i=1;i<=NF;i++){printf "slave+_hosts_="$i" "}{print ""}}' |awk -v RS="+" '{n+=1;printf $0n}'  > /root/K8s/ip_3.txt
sed -i '$d' /root/K8s/ip_3.txt   

echo "=============免交互处理===key fen fa======info========================" 
# #清除本地ssh环境
# \rm -f ~/.ssh/*
#创建秘钥对
# ssh-keygen -t dsa -f /root/.ssh/id_dsa -N  ""   &>/dev/null
#检查ip连通性,生成集群ip配置文件路径:/root/K8s/ip_3.txt
. /root/K8s/ip_3.txt



for  ips  in  $( awk -F  "="   '{print  $2}'  /root/K8s/ip_3.txt |xargs)
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


#配置免交互登录
#配置免交互登录
for  ip  in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt|xargs)
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


#检测分发效果连,批量配置主机名
for var_2 in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt|xargs)
do
  echo "==============host  $ip  info============================"
   let u+=i
   let i+=1
   ssh root@$var_2  " hostnamectl  set-hostname  K8s-add_node${i}"
   echo  "K8s-add_node${i}-$var_2"
done

####02
for var_3 in  $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt|xargs)
do
  echo "==============host  $var_3  info============================"
    ssh root@$var_3 "rm -f  /root/.ssh/id_dsa"
    ssh root@$var_3 "ssh-keygen -t dsa -f /root/.ssh/id_dsa -N  \"\"   &>/dev/null"
    ssh root@$var_3 "sshpass   -p  "$password_"  ssh-copy-id   -i  /root/.ssh/id_dsa.pub   root@$master_hosts_   -o StrictHostKeyChecking=no"
    scp /root/K8s/yum/ntpdate*  $var_3:/tmp
    ssh root@$var_3  "rpm  -ivh    /tmp/ntpdate*"
done


#添加ansible环境
#检测时间同步服务

systemctl   is-active  ntpd    ||{
  echo 时间同步服务异常,尝试修复中
   systemctl   restart   ntpd  || {

yum remove ntp  -y ;yum install ntp  -y    
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
systemctl   is-active  ntpd  
   }
}
###ntpdatentpdatentpdate
systemctl   is-active  ntpdate    ||{
  echo 时间同步服务异常,尝试修复中
   systemctl   restart   ntpd  || {
yum remove ntpdate  -y ;yum install ntpdate  -y    
#时间同步服务端启动,加开机自启
systemctl restart ntpdate
systemctl enable  ntpdate
systemctl status  ntpdate
systemctl   is-active  ntpdate  
   }
}
systemctl   is-active  ntpdate   ntpd ||{
  clear
  echo 时间服务修复失败
  echo 安装终止
  exit 1
}


for  VAR_IP in $(awk -F  "="   '{print  $2}' /root/K8s/ip_3.txt|xargs)
    do
        grep  ${VAR_IP}  /etc/ansible/hosts || {
        sed "/slave/a${VAR_IP}\n"   /etc/ansible/hosts  -i
        sed "/all/a${VAR_IP}\n"   /etc/ansible/hosts    -i
        }
       ansible  ${VAR_IP}  -m cron   -a    "backup=yes  minute=*/5 hour=* day=*  month=* weekday=*  name=\"Time synchronization\"  job=\"/usr/sbin/ntpdate $master_hosts_  >/dev/null 2>&1\""
       ansible $VAR_IP  -m  shell -a  "/usr/sbin/ntpdate $master_hosts_" 
done



