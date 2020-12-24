#!/bin/bash
#批量彻底删除已添加的指定node
#创建ansible免交互环境
#获取新增note集群ip
_cluster_ip  ()  {
if (whiptail --title "导入需要批量删除的node节点IP地址" --yes-button "YES" --no-button "NO"  --yesno "批量导入需要删除的node节点IP地址?" 10 60) then
    echo "You chose Skittles Exit status was $?."
    echo  ok
    rm -f   /root/K8s/.ip.txt*
    rm -f   /root/K8s/ip.txt
    > /root/K8s/ip.txt
cat >  /root/K8s/ip.txt <<EOF
#按下字母i键进入编辑模式,将ip批量粘贴进来即可
#格式如下(不包含#号,不能有空行,仅填写需要删除的note节点ip即可),导入完毕后wq! / x! 退出即可继续后面的操作
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
> /root/K8s/ip_4.txt
grep -v  "^#" /root/K8s/ip.txt >> /root/K8s/ip_4.txt
_del_node  ()  {
#master节点执行
#驱逐Node
timeout 60 kubectl  drain  --ignore-daemonsets  ${del_node_ip} ||{
    echo "驱逐pod超时,强制删除pod"
   kubectl  get pods --all-namespaces| grep  Terminating|awk  '{print $2,$1}' >/tmp/var_ter.log
IFS=$'\n'
OLDIFS="$IFS"
for  var_ter_01  in $(cat /tmp/var_ter.log)
        do  
        # echo $var_ter_01,ssss
         var_ter_a=$(echo $var_ter_01|awk  '{print $1}')
         var_ter_b=$(echo $var_ter_01|awk  '{print $2}')
         kubectl delete pod $var_ter_a --force --grace-period=0 -n ${var_ter_b}
    done 
IFS="$OLDIFS"
}

#删除node
kubectl  delete nodes  ${del_node_ip}
ansible  ${del_node_ip}   -m shell  -a   "rm -fv  /etc/kubernetes/ssl/*"
#删除csr
# kubectl  delete  csr    node-csr-teIYtaLoDVHqXACU6C3eS_jh_yDkSF5481JkDjAYA68  -n   kubelet-bootstrap
kubectl  delete  csr    $(kubectl  get csr|awk  '{print  $1}'|grep   -v NAME)  -n  kubelet-bootstrap
ansible  ${del_node_ip}   -m shell  -a   "systemctl  disable     kubelet kube-proxy docker"
ansible  ${del_node_ip}   -m shell  -a   "systemctl  stop     kubelet kube-proxy docker"
sed     "/${del_node_ip}/d"  /etc/ansible/hosts  -i 

}

#删除Node节点
for  del_node_ip  in  $( cat /root/K8s/ip_4.txt |xargs)
    do
_del_node
done



kubectl  get cs;kubectl  get csr;kubectl  get node;kubectl  get pods -o wide    --all-namespaces
