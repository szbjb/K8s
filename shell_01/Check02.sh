#!/bin/bash
#集群安装完毕状态检测
IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."$3}')) ||IP=$(hostname -I |xargs -n 1   | grep  $(ip route |head  -n 1 | awk    '{print  $3}'  |  awk  -F  '.'  '{print  $1"."$2"."}'))

clear
#k8s状态检测
echo "==============master节点健康检测 kube-apiserver  kube-controller-manager   kube-scheduler  etcd  kubelet kube-proxy docker=================="
ansible  master  -m shell  -a "systemctl is-active  kube-apiserver  kube-controller-manager   kube-scheduler  etcd  kubelet kube-proxy docker|xargs"


echo   "===============================================note节点监控检测 etcd  kubelet kube-proxy docker==============================================="
ansible  slave  -m shell  -a "systemctl is-active   etcd  kubelet kube-proxy docker|xargs"

##
echo "===============================================监测csr,cs,pvc,pv,storageclasses==============================================="
kubectl  get csr,cs,pvc,pv,storageclasses
echo "===============================================监测node节点labels==============================================="
kubectl get nodes --show-labels
echo "===============================================监测coredns是否正常工作==============================================="
kubectl  get pods  -n kube-system|grep dns|egrep "1/1" || {
while  [ true ]; do  sleep 10;  echo "等待credns就绪$(date |xargs -n 1 |grep ':')"; kubectl  get pods  -n kube-system|grep dns|egrep "1/1"  && break  1   ;done
}
kubectl  run --image=registry.cn-chengdu.aliyuncs.com/set/k8s/busybox:1.28.4 -it  --rm --restart=Never  dns-test /bin/nslookup kubernetes
echo "===============================================监测,pods状态==============================================="
kubectl get   pods -o wide   --all-namespaces
echo "===============================================监测node节点状态==============================================="
kubectl get   nodes -o wide
echo "================================================监测helm版本================================================"
helm  version

ss -lntup| grep heketi &&  {
echo "================================================监测glusterfs分布式对象存储状态================================================"
alias heketi-cli="/data/heketi/bin/heketi-cli --server \"http://${IP}:18080\" --user \"admin\" --secret \"adminkey\""
ClusterID=$(heketi-cli cluster list|awk    '{print $1}'|awk   -F  ':'  '{print  $2}')
Cluster_Info=$(heketi-cli cluster info   ${ClusterID})
Cluster_Info_01=$(heketi-cli cluster info   ${ClusterID})
}





# ##关机重启故障自动修复  "MatchNodeSelector"
# kubectl get pods --all-namespaces | grep MatchNodeSelector &&{
#     echo "驱逐pod超时,强制删除pod"
#   kubectl get pods --all-namespaces | grep MatchNodeSelector|awk  '{print $2,$1}' >/tmp/var_ter.log
# IFS=$'\n'
# OLDIFS="$IFS"
# for  var_ter_01  in $(cat /tmp/var_ter.log)
#         do  
#         # echo $var_ter_01,ssss
#          var_ter_a=$(echo $var_ter_01|awk  '{print $1}')
#          var_ter_b=$(echo $var_ter_01|awk  '{print $2}')
#          kubectl delete pod $var_ter_a --force --grace-period=0 -n ${var_ter_b}
#     done 
# IFS="$OLDIFS"
# }
# ##关机重启故障自动修复  "Terminating"
# kubectl get pods --all-namespaces | grep Terminating &&{
#     echo "驱逐pod超时,强制删除pod"
#   kubectl get pods --all-namespaces | grep Terminating|awk  '{print $2,$1}' >/tmp/var_ter.log
# IFS=$'\n'
# OLDIFS="$IFS"
# for  var_ter_01  in $(cat /tmp/var_ter.log)
#         do  
#         # echo $var_ter_01,ssss
#          var_ter_a=$(echo $var_ter_01|awk  '{print $1}')
#          var_ter_b=$(echo $var_ter_01|awk  '{print $2}')
#          kubectl delete pod $var_ter_a --force --grace-period=0 -n ${var_ter_b}
#     done 
# IFS="$OLDIFS"
# }